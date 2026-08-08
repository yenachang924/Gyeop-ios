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

    var body: some View {
        // Dynamic Type 극단에서도 깨지지 않게 — 내용은 스크롤, 버튼은 하단 고정
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("이게 나예요")
                        .font(DS.Typo.largeTitle)
                        .multilineTextAlignment(.center)
                    // 서브 텍스트는 headline — body는 "상당히 작다"는 피드백 (1차 시연)
                    Text("고른 것들이 그대로 물들어, 하나뿐인 카드가 됐어요.")
                        .font(DS.Typo.headline)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                CardView(card: card)
                    .padding(.horizontal, DS.Spacing.xl)
                    .scaleEffect(appeared ? 1 : 0.92)
                    .rotation3DEffect(
                        .degrees(appeared ? 0 : 22),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.55
                    )
                    .offset(y: appeared ? 0 : 240)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(DS.Spacing.m)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : DS.Motion.cardDeal) { appeared = true }
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
        .background(DS.Palette.background)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        CardRevealView(card: MockData.sampleCards[0])
            .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
    }
}
