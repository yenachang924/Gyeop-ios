import Core
import Foundation
import SwiftUI

/// 시드 → 카드 비주얼 파라미터의 결정적 변환.
/// 지금은 MeshGradient 색 9개까지만 — Metal `layerEffect` 질감은 CardKit 세션(S1 오후~)이 얹는다.
/// **계약: 같은 시드 = 같은 파라미터 = 픽셀 동일 렌더.**
public struct CardVisual: Equatable, Sendable {
    public let hues: [Double]

    public init(seed: String) {
        // 시드(sha256 hex)의 바이트를 2자리씩 잘라 9개 색상 각도로 변환
        let bytes = stride(from: 0, to: min(seed.count, 18), by: 2).map { offset -> Double in
            let start = seed.index(seed.startIndex, offsetBy: offset)
            let end = seed.index(start, offsetBy: 2)
            return Double(UInt8(seed[start..<end], radix: 16) ?? 0) / 255.0
        }
        hues = bytes.count == 9 ? bytes : Array(repeating: 0.5, count: 9)
    }

    public func meshColors(scheme: ColorScheme) -> [Color] {
        hues.map { hue in
            Color(
                hue: hue,
                saturation: scheme == .dark ? 0.55 : 0.45,
                brightness: scheme == .dark ? 0.45 : 0.85
            )
        }
    }
}
