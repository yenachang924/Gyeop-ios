import Core
import DesignSystem
import SwiftUI

/// "겹!" 순간 연출 (결정 R7 — 융합).
///
/// 두 카드의 대표색 원이 위/아래에서 대칭으로 다가와 gooey(메타볼) 필터로 액체처럼
/// 이어붙는다 — 좌우 배치는 "내 카드=왼쪽 고정"이 대등하지 않아 버티컬로 확정된 결정.
/// 접점은 두 카드 색이 섞인 중간색으로 물든다. 융합이 착지하는 시점에 액센트 링 파동
/// 1회(결정 R1: accent는 겹 성립 순간 전용)와 "겹!" 워드가 뒤따른다.
///
/// 모든 움직임은 SwiftUI 스프링 트랜잭션(`DS.Motion.*`)을 그대로 탄다 — 임의 커브 없음.
/// `DS.Motion.Moment.total`이 지나면 `onFinished`를 호출한다.
/// Reduce Motion에서는 융합 최종 프레임만 정지 상태로 잠깐 보여주고 넘어간다.
public struct GyeopMomentView: View {
    private let myColor: Color
    private let counterpartColor: Color
    private let counterpartName: String
    private let onFinished: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mergeProgress: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @State private var wordShown = false

    public init(
        myCard: CardSnapshot,
        counterpartCard: CardSnapshot,
        onFinished: @escaping @MainActor () -> Void
    ) {
        myColor = CardVisual(seed: myCard.seed, style: myCard.leisureStyle).dominantColor
        counterpartColor = CardVisual(
            seed: counterpartCard.seed, style: counterpartCard.leisureStyle
        ).dominantColor
        counterpartName = counterpartCard.nickname
        self.onFinished = onFinished
    }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                // 위(내 카드 색) → 접점(혼합색) → 아래(상대 카드 색). 메타볼 마스크가
                // 블롭 모양만 남기므로 접점이 자연스럽게 두 색의 중간으로 물든다.
                LinearGradient(
                    colors: [
                        myColor,
                        myColor.mix(with: counterpartColor, by: 0.5),
                        counterpartColor,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask { GooBlobs(progress: mergeProgress) }

                Circle()
                    .stroke(DS.Palette.accent, lineWidth: Layout.ringLineWidth)
                    .frame(width: side * Layout.ringDiameterRatio, height: side * Layout.ringDiameterRatio)
                    .scaleEffect(
                        Layout.ringStartScale
                            + ringProgress * (Layout.ringEndScale - Layout.ringStartScale)
                    )
                    .opacity(ringProgress == 0 ? 0 : Layout.ringStartOpacity * (1 - ringProgress))

                // 블롭 위 텍스트는 카드 위 텍스트와 같은 규칙 — CardVisual이 흰 글자
                // 4.5:1 대비를 보장하는 색만 내므로 고정 흰색.
                Text("겹!")
                    .font(DS.Typo.largeTitle)
                    .foregroundStyle(.white)
                    .scaleEffect(wordShown ? 1 : Layout.wordStartScale)
                    .opacity(wordShown ? 1 : 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear(perform: begin)
        .task {
            try? await Task.sleep(
                for: .seconds(reduceMotion ? Layout.reducedMotionHold : DS.Motion.Moment.total)
            )
            onFinished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(counterpartName)님과 겹치는 중")
    }

    private func begin() {
        guard !reduceMotion else {
            mergeProgress = 1
            wordShown = true
            return
        }
        withAnimation(DS.Motion.merge) { mergeProgress = 1 }
        withAnimation(DS.Motion.ringPulse.delay(DS.Motion.Moment.ringDelay)) { ringProgress = 1 }
        withAnimation(DS.Motion.standard.delay(DS.Motion.Moment.wordDelay)) { wordShown = true }
    }
}

/// 메타볼 융합 마스크 — 두 원을 blur 후 alphaThreshold로 잘라 액체처럼 이어붙인다.
/// `Animatable` 채택으로 progress가 SwiftUI 스프링 보간을 프레임 단위로 그대로 받는다.
private struct GooBlobs: View, Animatable {
    var progress: CGFloat

    // View는 @MainActor지만 Animatable 요구는 비격리 — CGFloat만 담는 Sendable 값 타입이라
    // 저장 프로퍼티 접근이 비격리로 허용된다 (SE-0434).
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let radius = side * Layout.blobRadiusRatio
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // 시작: 위/아래 가장자리 근처. 끝: 중심에서 반지름보다 가까워 서로 겹친다 (대칭 — R7).
            let startOffset = size.height / 2 - radius
            let endOffset = radius * Layout.blobRestOverlap
            let clamped = min(max(progress, 0), 1)
            let offset = startOffset + (endOffset - startOffset) * clamped

            context.addFilter(.alphaThreshold(min: 0.5))
            context.addFilter(.blur(radius: radius * Layout.gooBlurRatio))
            context.drawLayer { layer in
                for direction: CGFloat in [-1, 1] {
                    let blobCenter = CGPoint(x: center.x, y: center.y + direction * offset)
                    let rect = CGRect(
                        x: blobCenter.x - radius,
                        y: blobCenter.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    layer.fill(Path(ellipseIn: rect), with: .color(.black))
                }
            }
        }
    }
}

/// 연출 기하 상수 — 커스텀 비주얼(CardKit 허용 영역)의 형태 정의.
/// 링 수치는 docs/gyeop-prototype.html `.bump-ring`(2.5px, scale 0.5→1.5, opacity 0.9→0) 기준.
private enum Layout {
    /// 블롭 반지름 (짧은 변 대비 비율)
    static let blobRadiusRatio: CGFloat = 0.24
    /// 정지 시 두 원 중심이 화면 중심에서 떨어진 거리 (반지름 배수) — 1 미만이면 겹친다.
    static let blobRestOverlap: CGFloat = 0.55
    /// goo 블러 강도 (반지름 배수) — 클수록 이어붙는 목이 두꺼워진다.
    static let gooBlurRatio: CGFloat = 0.30
    static let ringDiameterRatio: CGFloat = 0.58
    static let ringLineWidth: CGFloat = 2.5
    static let ringStartScale: CGFloat = 0.5
    static let ringEndScale: CGFloat = 1.5
    static let ringStartOpacity: Double = 0.9
    static let wordStartScale: CGFloat = 0.6
    /// Reduce Motion — 최종 프레임을 보여주는 시간
    static let reducedMotionHold: TimeInterval = 0.6
}

#Preview("겹! 순간") {
    GyeopMomentView(
        myCard: MockData.sampleCards[0],
        counterpartCard: MockData.sampleCards[1]
    ) {}
    .frame(width: 320, height: 320)
}
