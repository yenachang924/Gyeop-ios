import Core
import Foundation
import SwiftUI

/// 시드 → 카드 비주얼 파라미터의 결정적 변환.
/// **계약: 같은 시드 = 같은 파라미터 = 픽셀 동일 렌더.**
///
/// F56 (오라 파스텔) + F61 (소유자 그라디언트 레퍼런스 2차): 색 규율.
/// · 색 종류를 줄였다 (F61): 한 카드는 **4색 앵커**. 25점 무작위 배치(F25)는 은퇴 —
///   앵커 4색이 카드 네 코너에 앉고 나머지 제어점은 **이중선형 보간**으로 그 사이를
///   흐른다. 레퍼런스(오라 배경화면)의 "큰 면이 부드럽게 이어지는" 인상이 목표다
/// · 앵커 hue는 기준 hue에서 **이웃 간격(0.08~0.15)으로만** 벌어진다 — 레퍼런스의
///   파랑→보라→분홍→주황처럼 인접 색상들이 한 방향으로 스윕한다
/// · 밝기 결은 F56 유지: **밝고 뽀얀 고명도 저채도**(채도 25~45·명도 82~96)
/// · 카드 위 텍스트는 **잉크**(`inkColor`) — 채도·명도는 잉크 대비 4.5:1이
///   항상 만족되도록 보정된다 (명도를 올리고, 모자라면 채도를 뺀다)
public struct CardVisual: Equatable, Sendable {
    /// 하나의 MeshGradient 제어점. HSB(SwiftUI `Color(hue:saturation:brightness:)`) 성분.
    public struct ControlPoint: Equatable, Sendable {
        public let hue: Double
        public let saturation: Double
        public let brightness: Double
    }

    /// 5×5 MeshGradient 제어점 25개 (행 우선: 좌상단 → 우하단).
    public let controlPoints: [ControlPoint]

    /// MeshGradient 격자 한 변의 제어점 수 (결정 R2: 5×5).
    public static let meshDimension = 5
    public static let controlPointCount = meshDimension * meshDimension
    /// 오라 파스텔 채도 대역 (F56) — 이보다 진하면 원색, 옅으면 회색이 된다.
    public static let saturationRange: ClosedRange<Double> = 0.25...0.45
    /// 오라 파스텔 명도 대역 (F56) — 뽀얀 밝기. 대비 보정으로 상한 위까지 올라갈 수 있다.
    public static let brightnessRange: ClosedRange<Double> = 0.82...0.96
    /// 대비 보정이 명도를 올릴 수 있는 천장 — 1.0까지 가면 흰색이 되어 오라가 사라진다.
    public static let brightnessCeiling: Double = 0.97
    /// WCAG AA 기준 잉크 텍스트 최소 대비 (F56 — 흰 텍스트 기준에서 반전).
    public static let minimumInkContrast: Double = 4.5

    /// 한 카드를 구성하는 앵커 색의 수 (F61 — "색깔 종류를 줄이고").
    public static let anchorCount = 4
    /// 앵커 사이 hue 간격 — 인접 색상으로만 흐른다 (F61 레퍼런스 스윕).
    public static let hueStepRange: ClosedRange<Double> = 0.08...0.15

    /// 카드 위 텍스트 잉크 — 카드 그라데이션은 라이트·다크 동일하므로(R2) 잉크도 고정값이다.
    /// 순흑 대신 카드의 결에 맞는 딥 플럼 톤 (#33283A).
    public static let inkColor = Color(red: inkRGB.r, green: inkRGB.g, blue: inkRGB.b)
    static let inkRGB = (r: 0x33 / 255.0, g: 0x28 / 255.0, b: 0x3A / 255.0)

    public init(seed: String) {
        var rng = SplitMix64(seed: Self.seedValue(from: seed))

        // 4색 앵커: 기준 hue에서 이웃 간격으로만 스윕 (F61) — 레퍼런스처럼
        // 파랑→보라→분홍→주황 같은 인접 색의 흐름이 된다.
        var hue = Double.random(in: 0...1, using: &rng)
        let anchors: [ControlPoint] = (0..<Self.anchorCount).map { index in
            if index > 0 {
                hue = (hue + Double.random(in: Self.hueStepRange, using: &rng))
                    .truncatingRemainder(dividingBy: 1)
            }
            let rawSaturation = Double.random(in: Self.saturationRange, using: &rng)
            let rawBrightness = Double.random(in: Self.brightnessRange, using: &rng)
            let corrected = Self.colorGuaranteeingInkContrast(
                hue: hue, saturation: rawSaturation, brightness: rawBrightness
            )
            return ControlPoint(hue: hue, saturation: corrected.saturation, brightness: corrected.brightness)
        }

        // 앵커를 네 코너(좌상·우상·좌하·우하)에 두고, 25개 제어점은 이중선형 보간으로
        // 그 사이를 흐른다 — 큰 면이 부드럽게 이어지는 오라 (F61, 무작위 배치 은퇴).
        let n = Self.meshDimension
        controlPoints = (0..<Self.controlPointCount).map { index in
            let u = Double(index % n) / Double(n - 1)
            let v = Double(index / n) / Double(n - 1)
            let weights = [(1 - u) * (1 - v), u * (1 - v), (1 - u) * v, u * v]
            let blended = Self.blend(anchors: anchors, weights: weights)
            let corrected = Self.colorGuaranteeingInkContrast(
                hue: blended.hue, saturation: blended.saturation, brightness: blended.brightness
            )
            return ControlPoint(
                hue: blended.hue, saturation: corrected.saturation, brightness: corrected.brightness
            )
        }
    }

    /// 가중 블렌드 — hue는 원형(색상환)이라 벡터 합으로 섞는다. 앵커들이 인접
    /// 색상이라(스윕 상한 0.45) 벡터 합이 0에 가까워지는 퇴화는 실질적으로 없다.
    private static func blend(
        anchors: [ControlPoint], weights: [Double]
    ) -> (hue: Double, saturation: Double, brightness: Double) {
        var x = 0.0, y = 0.0, saturation = 0.0, brightness = 0.0
        for (anchor, weight) in zip(anchors, weights) {
            x += weight * cos(anchor.hue * 2 * .pi)
            y += weight * sin(anchor.hue * 2 * .pi)
            saturation += weight * anchor.saturation
            brightness += weight * anchor.brightness
        }
        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        return (hue, saturation, brightness)
    }

    /// MeshGradient에 바로 넣을 수 있는 25색.
    public var colors: [Color] {
        controlPoints.map { Color(hue: $0.hue, saturation: $0.saturation, brightness: $0.brightness) }
    }

    /// 카드를 한 색으로 대표할 때 쓰는 중앙 제어점 색 — "겹!" 융합 연출의 원(GyeopMomentView) 등.
    /// 격자 중앙이라 카드 첫인상과 가장 가깝고, 시드가 같으면 언제나 같은 색이다.
    public var dominantColor: Color {
        colors[Self.controlPointCount / 2]
    }

    private static func seedValue(from hex: String) -> UInt64 {
        var result: UInt64 = 0
        var index = hex.startIndex
        while index < hex.endIndex {
            let end = hex.index(index, offsetBy: 16, limitedBy: hex.endIndex) ?? hex.endIndex
            if let chunk = UInt64(hex[index..<end], radix: 16) {
                result ^= chunk
            }
            index = end
        }
        return result == 0 ? 0x9E3779B97F4A7C15 : result
    }

    /// 파스텔 대역만으로는 전 색상에서 잉크 대비를 보장할 수 없다 — 특히 파랑 계열은
    /// 같은 HSB 명도에서도 상대 휘도가 낮다. 부족하면 **명도를 먼저 올리고**(천장까지),
    /// 그래도 모자라면 **채도를 뺀다**. 두 축 모두 "더 뽀얘지는" 방향이라 오라의 결을 지킨다.
    static func colorGuaranteeingInkContrast(
        hue: Double, saturation: Double, brightness: Double
    ) -> (saturation: Double, brightness: Double) {
        var saturation = saturation
        var brightness = brightness
        while contrastAgainstInk(hue: hue, saturation: saturation, brightness: brightness)
            < minimumInkContrast
        {
            if brightness < brightnessCeiling {
                brightness = min(brightness + 0.01, brightnessCeiling)
            } else if saturation > 0 {
                saturation = max(saturation - 0.01, 0)
            } else {
                break
            }
        }
        return (saturation, brightness)
    }

    /// 배경색(밝음) 대 잉크(어두움)의 WCAG 대비.
    static func contrastAgainstInk(hue: Double, saturation: Double, brightness: Double) -> Double {
        let backgroundLuminance = relativeLuminance(
            hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        )
        return (backgroundLuminance + 0.05) / (inkLuminance + 0.05)
    }

    private static let inkLuminance = relativeLuminance(inkRGB)

    private static func hsbToRGB(hue: Double, saturation: Double, brightness: Double) -> (r: Double, g: Double, b: Double) {
        let h = hue * 6
        let sector = Int(h.rounded(.down)) % 6
        let fraction = h - h.rounded(.down)
        let p = brightness * (1 - saturation)
        let q = brightness * (1 - saturation * fraction)
        let t = brightness * (1 - saturation * (1 - fraction))
        switch sector {
        case 0: return (brightness, t, p)
        case 1: return (q, brightness, p)
        case 2: return (p, brightness, t)
        case 3: return (p, q, brightness)
        case 4: return (t, p, brightness)
        default: return (brightness, p, q)
        }
    }

    private static func relativeLuminance(_ rgb: (r: Double, g: Double, b: Double)) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb.r) + 0.7152 * linear(rgb.g) + 0.0722 * linear(rgb.b)
    }
}

/// SplitMix64 — 시드 하나로 재현 가능한 값 스트림을 뽑기 위한 경량 PRNG.
/// (암호학적 용도 아님. 카드 비주얼의 결정적 다양성 생성 전용.)
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
