import Core
import Foundation
import SwiftUI

/// 시드 → 카드 비주얼 파라미터의 결정적 변환.
/// **계약: 같은 시드(+성향) = 같은 파라미터 = 픽셀 동일 렌더.**
///
/// F21→F24 (1차 시연 피드백): 한 카드의 색은 **7색 팔레트**로 절제하되(25점 무작위는
/// 무지개 노이즈), 웜/쿨 이분법(F21)은 과해서 폐기 — 기준 색상은 색상환 전체에서
/// 시드가 뽑아 카드마다 형형색색하고, 성향은 색의 "결"에만 은은하게 배어든다
/// (`docs/card-color-guide.md`):
/// · 활발 = 7색이 넓게 퍼진다(형형색색) / 잔잔 = 좁게 모인다(차분)
/// · 실외 = 밝은 명도대 / 실내 = 깊은 명도대
/// 채도·명도는 카드 위 흰 텍스트가 항상 WCAG AA 4.5:1 대비를 만족하도록 좁힌 범위
/// (`saturationRange`·`brightnessRange`) 안에서 결정된다.
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
    public static let saturationRange: ClosedRange<Double> = 0.70...0.80
    public static let brightnessRange: ClosedRange<Double> = 0.45...0.62
    /// WCAG AA 기준 흰 텍스트 최소 대비.
    public static let minimumWhiteContrast: Double = 4.5

    /// 한 카드를 구성하는 색의 수 (F21 — "색상 다양성 7개 정도, 오묘한 분위기").
    public static let paletteCount = 7
    /// 7색이 퍼지는 색상환 폭 (F24 절충값). 활발은 넓게(형형색색), 잔잔은 좁게(차분).
    public static let hueSpreadActive: Double = 0.36
    public static let hueSpreadCalm: Double = 0.24
    public static let hueSpreadNeutral: Double = 0.30

    /// - Parameter style: 색의 결을 정한다 (card-color-guide.md — 퍼짐과 밝기).
    ///   기준 색상 자체는 항상 시드가 색상환 전체에서 뽑는다 (F24: 카드마다 형형색색).
    public init(seed: String, style: LeisureStyle? = nil) {
        var rng = SplitMix64(seed: Self.seedValue(from: seed))

        // 1) 기준 색상: 시드가 색상환 전체에서 — 취미·이름·이모지·성향이 종합된 결과.
        let baseHue = Double.random(in: 0...1, using: &rng)

        // 2) 퍼짐: 에너지가 7색이 얼마나 넓게 퍼질지를 정한다 (이분법 아닌 "결").
        let spread: Double
        switch style?.energy {
        case .active: spread = Self.hueSpreadActive
        case .calm: spread = Self.hueSpreadCalm
        case nil: spread = Self.hueSpreadNeutral
        }

        // 3) 명도대: 장소가 밝기의 결을 정한다 (실외 = 밝음, 실내 = 깊음).
        let brightnessBand: ClosedRange<Double>
        switch style?.venue {
        case .outdoor: brightnessBand = 0.53...0.62
        case .indoor: brightnessBand = 0.45...0.54
        case nil: brightnessBand = Self.brightnessRange
        }

        // 4) 7색 팔레트: 기준 색상 주변으로 고르게 퍼뜨리고 + 시드 지터.
        let palette: [ControlPoint] = (0..<Self.paletteCount).map { index in
            let position = Double(index) / Double(Self.paletteCount - 1) - 0.5
            let jitter = Double.random(in: -0.015...0.015, using: &rng)
            let hue = (baseHue + position * spread + jitter + 1)
                .truncatingRemainder(dividingBy: 1)
            let saturation = Double.random(in: Self.saturationRange, using: &rng)
            let rawBrightness = Double.random(in: brightnessBand, using: &rng)
            let brightness = Self.brightnessGuaranteeingContrast(
                hue: hue, saturation: saturation, brightness: rawBrightness
            )
            return ControlPoint(hue: hue, saturation: saturation, brightness: brightness)
        }

        // 5) 25점 배치: 대각선 흐름으로 깔아 인접 점이 유사색이 되게 한다 — 색이 스며드는
        //    결(오묘함)은 배치가 만든다. 시드 시프트로 카드마다 흐름의 시작점이 달라진다.
        let shift = Int.random(in: 0..<Self.paletteCount, using: &rng)
        controlPoints = (0..<Self.controlPointCount).map { index in
            let row = index / Self.meshDimension
            let column = index % Self.meshDimension
            return palette[(row + column + shift) % Self.paletteCount]
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

    /// `brightnessRange` 상한(0.62)은 노랑 계열 색상(hue≈60°)에서는 흰 텍스트 대비를
    /// 4.5:1 밑으로 떨어뜨린다 — 채도·명도 범위만으로는 전 색상에서 대비를 보장할 수
    /// 없다는 뜻이라, 실제로 필요한 색상에서만 명도를 낮춰 대비를 지킨다.
    private static func brightnessGuaranteeingContrast(
        hue: Double, saturation: Double, brightness: Double
    ) -> Double {
        var candidate = brightness
        while candidate > 0,
            contrastAgainstWhite(hue: hue, saturation: saturation, brightness: candidate)
                < minimumWhiteContrast
        {
            candidate -= 0.01
        }
        return max(candidate, 0)
    }

    static func contrastAgainstWhite(hue: Double, saturation: Double, brightness: Double) -> Double {
        let rgb = hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        let luminance = relativeLuminance(rgb)
        return 1.05 / (luminance + 0.05)
    }

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
