import DesignSystem
import SwiftUI

/// 카드가 등장하는 화면(리빌·컬렉션·상세) 전용 배경 — POSTECH 메인 컬러에 앵커한 파스텔
/// 톤으로 화면 전체를 서서히 일렁이게 한다("Apple 다이나믹 배경화면" 느낌). 카드 자체의
/// MeshGradient(고대비, 전체 색상 랜덤)와는 의도적으로 분리 — 배경은 브랜드 톤 하나로
/// 묶어 차분하게, 카드만 도드라지게 한다. `.ultraThinMaterial` 대신 `.regularMaterial`을
/// 쓰는 이유: 시스템 라벨 텍스트(검정/흰색)가 그 위에 그대로 얹히므로 대비를 지키려면
/// 더 두꺼운 프로스팅이 필요하다.
///
/// 코너 4점은 화면 경계에 고정하고 나머지 5점만 흔들어 프레임 가장자리에 빈틈이 생기지
/// 않게 한다. Reduce Motion에서는 `TimelineView`가 정지해 흔들림 없는 정적 그라디언트로
/// 남는다 (CLAUDE.md Motion 원칙).
public struct CardAmbientBackground: View {
    private let seed: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?

    /// POSTECH 팔레트를 흰색과 섞어 파스텔화 — 배경은 카드보다 훨씬 옅고 차분해야 한다.
    private static let pastelSwatches: [Color] = [
        pastel(0xA6, 0x19, 0x55), // Red — 메인
        pastel(0xF6, 0xA7, 0x00), // Orange
        pastel(0xDA, 0xBA, 0x65), // Gold
        pastel(0x74, 0xD6, 0xE4), // Mint
        pastel(0x2F, 0x6F, 0x74), // Teal
    ]

    public init(seed: String) {
        self.seed = seed
    }

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = startDate.map { timeline.date.timeIntervalSince($0) } ?? 0
            MeshGradient(
                width: 3,
                height: 3,
                points: shimmerPoints(elapsed: elapsed),
                colors: ambientColors()
            )
            .onAppear { if startDate == nil { startDate = timeline.date } }
        }
        .overlay(.regularMaterial)
        .ignoresSafeArea()
    }

    /// 9개 제어점 — 레드(메인)를 중심·모서리에 배치해 톤을 앵커하고, 나머지 팔레트를
    /// 가장자리 중점에 배치해 다양성을 살짝만 남긴다. 시드로 회전시켜 카드마다 살짝 다르게.
    private func ambientColors() -> [Color] {
        let swatches = Self.pastelSwatches
        let rotation = abs(seed.hashValue) % swatches.count
        let rotated = Array(swatches[rotation...] + swatches[..<rotation])
        let main = rotated[0]
        return [
            main, rotated[1], main,
            rotated[2], main, rotated[3],
            main, rotated[4], main,
        ]
    }

    private static func pastel(_ r: UInt8, _ g: UInt8, _ b: UInt8, whiteMix: Double = 0.62) -> Color {
        let rf = Double(r) / 255, gf = Double(g) / 255, bf = Double(b) / 255
        return Color(
            red: rf + (1 - rf) * whiteMix,
            green: gf + (1 - gf) * whiteMix,
            blue: bf + (1 - bf) * whiteMix
        )
    }

    private func shimmerPoints(elapsed: TimeInterval) -> [SIMD2<Float>] {
        let t = Float(elapsed)
        func drift(_ phase: Float) -> Float { sin(t * 0.18 + phase) * 0.07 }

        return [
            SIMD2(0, 0),
            SIMD2(0.5 + drift(0), 0),
            SIMD2(1, 0),
            SIMD2(0, 0.5 + drift(1.6)),
            SIMD2(0.5 + drift(3.1), 0.5 + drift(4.7)),
            SIMD2(1, 0.5 + drift(2.4)),
            SIMD2(0, 1),
            SIMD2(0.5 + drift(5.5), 1),
            SIMD2(1, 1),
        ]
    }
}

#Preview {
    CardAmbientBackground(seed: "preview-seed")
}
