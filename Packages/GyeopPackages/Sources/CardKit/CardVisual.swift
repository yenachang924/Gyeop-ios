import Core
import Foundation
import SwiftUI

/// 시드 → 카드 비주얼 파라미터의 결정적 변환.
/// **계약: 같은 시드 = 같은 파라미터 = 픽셀 동일 렌더.**
///
/// 시드(sha256 hex)로 SplitMix64 PRNG를 초기화해 3×3 MeshGradient 제어점 9개의
/// 색상(H)·채도(S)·명도(B)를 뽑는다. 채도·명도는 카드 위 흰 텍스트가 항상 WCAG AA
/// 4.5:1 대비를 만족하도록 좁힌 범위(`saturationRange`·`brightnessRange`) 안에서 결정된다.
public struct CardVisual: Equatable, Sendable {
    /// 하나의 MeshGradient 제어점. HSB(SwiftUI `Color(hue:saturation:brightness:)`) 성분.
    public struct ControlPoint: Equatable, Sendable {
        public let hue: Double
        public let saturation: Double
        public let brightness: Double
    }

    /// 3×3 MeshGradient 제어점 9개 (행 우선: 좌상단 → 우하단).
    public let controlPoints: [ControlPoint]

    public static let controlPointCount = 9
    public static let saturationRange: ClosedRange<Double> = 0.70...0.80
    public static let brightnessRange: ClosedRange<Double> = 0.45...0.62
    /// WCAG AA 기준 흰 텍스트 최소 대비.
    public static let minimumWhiteContrast: Double = 4.5

    public init(seed: String) {
        var rng = SplitMix64(seed: Self.seedValue(from: seed))
        controlPoints = (0..<Self.controlPointCount).map { _ in
            let hue = Double.random(in: 0...1, using: &rng)
            let saturation = Double.random(in: Self.saturationRange, using: &rng)
            let rawBrightness = Double.random(in: Self.brightnessRange, using: &rng)
            let brightness = Self.brightnessGuaranteeingContrast(
                hue: hue, saturation: saturation, brightness: rawBrightness
            )
            return ControlPoint(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    /// MeshGradient에 바로 넣을 수 있는 9색.
    public var colors: [Color] {
        controlPoints.map { Color(hue: $0.hue, saturation: $0.saturation, brightness: $0.brightness) }
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
