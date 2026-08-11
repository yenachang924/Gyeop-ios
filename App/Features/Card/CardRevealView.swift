import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 직후 카드 리빌. 카드 비주얼은 CardKit 목업(시드 기반 MeshGradient) —
/// Metal 셰이더 실구현이 오면 이 화면은 그대로 두고 CardView만 진화한다.
struct CardRevealView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let card: CardSnapshot

    /// 카드 딜 인 (F6 — 토스 카드 발급 모티브): 아래에서 떠오르며 틸트가 풀린다.
    @State private var appeared = false
    /// 컬렉션으로 떠나는 전환 (F29) — 카드가 위로 실려 나가고 화면이 비워진다.
    @State private var leaving = false

    var body: some View {
        // Dynamic Type 극단에서도 깨지지 않게 — 내용은 스크롤, 버튼은 하단 고정
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    // F38: 리빌의 주인공 문구라 largeTitle보다 한 급 크게
                    Text("이게 나예요")
                        .font(DS.Typo.reveal)
                        .multilineTextAlignment(.center)
                    // 서브 텍스트는 headline — body는 "상당히 작다"는 피드백 (1차 시연)
                    Text("고른 것들이 그대로 물들어, 하나뿐인 카드가 됐어요.")
                        .font(DS.Typo.headline)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(leaving ? 0 : 1)
                .offset(y: leaving ? -24 : 0)

                CardView(card: card)
                    .padding(.horizontal, DS.Spacing.xl)
                    .scaleEffect(appeared ? (leaving ? 0.92 : 1) : 0.92)
                    .rotation3DEffect(
                        .degrees(appeared ? 0 : 22),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.55
                    )
                    .offset(y: leaving ? -140 : (appeared ? 0 : 240))
                    .opacity(appeared ? (leaving ? 0 : 1) : 0)
            }
            .padding(DS.Spacing.m)
        }
        // 제목과 카드가 한 덩어리로 화면 중앙에 앉되, 중앙보다 살짝 위로 (F38)
        .defaultScrollAnchor(.center)
        .safeAreaPadding(.bottom, Layout.raise)
        .onAppear {
            withAnimation(reduceMotion ? nil : DS.Motion.cardDeal) { appeared = true }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await goToCollection() }
            } label: {
                Text("나의 카드로")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsProminentButton()
            .disabled(leaving)
            .opacity(leaving ? 0 : 1)
            .accessibilityIdentifier("reveal.toCollection")
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
        .navigationBarBackButtonHidden()
    }

    /// 카드가 위로 실려 나간 뒤 컬렉션으로 넘어간다 (F29) — 화면이 뚝 끊기지 않게.
    /// Reduce Motion에서는 연출 없이 즉시 이동.
    private func goToCollection() async {
        guard !reduceMotion else {
            await model.enterCollection()
            return
        }
        withAnimation(DS.Motion.depart) { leaving = true }
        try? await Task.sleep(for: .seconds(Depart.hold))
        await model.enterCollection()
    }

    private enum Depart {
        /// 퇴장 애니메이션(DS.Motion.depart 0.3s)이 **끝까지 재생된 뒤** 화면을 넘긴다 (F39).
        /// 이전에는 중간에 잘려 툭 끊기는 인상이었다.
        static let hold: TimeInterval = 0.34
    }

    private enum Layout {
        /// 시각적 중앙은 기하학적 중앙보다 살짝 위다 (F38).
        static let raise: CGFloat = 56
    }
}

#Preview {
    NavigationStack {
        CardRevealView(card: MockData.sampleCards[0])
            .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
    }
}
