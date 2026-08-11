import Core
import Foundation
import SwiftUI

/// 시드 → 카드 비주얼 파라미터의 결정적 변환.
/// **계약: 같은 시드 = 같은 파라미터 = 픽셀 동일 렌더.**
///
/// F56 (카드 리디자인 라운드, 소유자 오라 레퍼런스): 색 규율을 **오라 파스텔**로 개정.
/// · 한 카드는 **7색 팔레트** — 상한은 F25에서 승계
/// · 7색의 색상은 각각 색상환 **전체에서 무작위**, 25개 제어점 배치도 **무작위** (F25 승계)
/// · 은은함의 방향이 뒤집혔다: 딥 톤(채도 70~80·명도 45~62)이 아니라 **밝고 뽀얀
///   고명도 저채도**(채도 25~45·명도 82~96)가 오라를 만든다
/// · 카드 위 텍스트는 흰색 → **잉크**(`inkColor`) — 채도·명도는 잉크 대비 4.5:1이
///   항상 만족되도록 보정된다 (보정 방향도 반전: 명도를 올리고, 모자라면 채도를 뺀다)
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

    /// 한 카드를 구성하는 색의 수 (F21에서 유지 — "색상 다양성 7개 정도").
    public static let paletteCount = 7

    /// 카드 위 텍스트 잉크 — 카드 그라데이션은 라이트·다크 동일하므로(R2) 잉크도 고정값이다.
    /// 순흑 대신 카드의 결에 맞는 딥 플럼 톤 (#33283A).
    public static let inkColor = Color(red: inkRGB.r, green: inkRGB.g, blue: inkRGB.b)
    static let inkRGB = (r: 0x33 / 255.0, g: 0x28 / 255.0, b: 0x3A / 255.0)

    public init(seed: String) {
        var rng = SplitMix64(seed: Self.seedValue(from: seed))

        // 7색 팔레트: 색상은 각각 색상환 전체에서 무작위 (F25 — 색 제한 없음).
        let palette: [ControlPoint] = (0..<Self.paletteCount).map { _ in
            let hue = Double.random(in: 0...1, using: &rng)
            let rawSaturation = Double.random(in: Self.saturationRange, using: &rng)
            let rawBrightness = Double.random(in: Self.brightnessRange, using: &rng)
            let corrected = Self.colorGuaranteeingInkContrast(
                hue: hue, saturation: rawSaturation, brightness: rawBrightness
            )
            return ControlPoint(hue: hue, saturation: corrected.saturation, brightness: corrected.brightness)
        }

        // 25개 제어점에 무작위 배치 (F25). MeshGradient 보간이 점 사이를 부드럽게
        // 섞으므로, 같은 색이 이웃해도 자연스러운 면이 된다.
        controlPoints = (0..<Self.controlPointCount).map { _ in
            palette[Int.random(in: 0..<Self.paletteCount, using: &rng)]
        }
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
