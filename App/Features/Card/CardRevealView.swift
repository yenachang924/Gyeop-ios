import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 직후 카드 리빌. 카드 비주얼은 CardKit 목업(시드 기반 MeshGradient) —
/// Metal 셰이더 실구현이 오면 이 화면은 그대로 두고 CardView만 진화한다.
struct CardRevealView: View {
    @Environment(AppModel.self) private var model
    let card: CardSnapshot

    var body: some View {
        // Dynamic Type 극단에서도 깨지지 않게 — 내용은 스크롤, 버튼은 하단 고정
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("당신의 카드가 완성됐어요")
                        .heroTitleStyle()
                        .multilineTextAlignment(.center)
                    Text("같은 입력이면 언제나 같은 카드 — 카드가 곧 당신입니다")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                CardView(card: card)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .padding(DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await model.enterCollection() }
            } label: {
                Text("컬렉션으로")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("reveal.toCollection")
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(CardAmbientBackground(seed: card.seed))
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        CardRevealView(card: MockData.sampleCards[0])
            .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
    }
}
