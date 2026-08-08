import Core
import DesignSystem
import SwiftUI

/// 온보딩 3단계: 관심사(최대 5) → 성향 2×2 → 닉네임·한 줄·이모지 원탭 → 카드 리빌.
/// 카피는 docs/gyeop-prototype.html 기준.
struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var model

    @State private var path: [Step] = []
    @State private var draft = OnboardingDraft()

    enum Step: Hashable {
        case style
        case profile
        case reveal(CardSnapshot)
    }

    var body: some View {
        NavigationStack(path: $path) {
            InterestsStepView(selected: $draft.interests) {
                path.append(.style)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .style:
                    StyleStepView(selected: $draft.style) {
                        path.append(.profile)
                    }
                case .profile:
                    ProfileStepView(draft: $draft) {
                        await createCard()
                    }
                case .reveal(let card):
                    CardRevealView(card: card)
                }
            }
        }
    }

    private func createCard() async {
        guard let style = draft.style else { return }
        let card = await model.completeOnboarding(
            nickname: draft.nickname,
            tagline: draft.tagline,
            emoji: draft.emoji,
            interests: draft.interests,
            style: style
        )
        if let card {
            path.append(.reveal(card))
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
