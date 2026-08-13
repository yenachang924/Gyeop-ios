import Core
import DesignSystem
import SwiftUI

/// 온보딩 3단계: 관심사(최대 5) → MBTI(건너뛰기 가능) → 닉네임·한 줄·이모지 원탭 → 카드 리빌.
/// 카피 기준은 카드 리디자인 라운드 시안(review/proposals/mbti-card-redesign.html).
struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var model

    @State private var path: [Step] = []
    @State private var draft = OnboardingDraft()

    enum Step: Hashable {
        case mbti
        case profile
        case reveal(CardSnapshot)
    }

    var body: some View {
        NavigationStack(path: $path) {
            InterestsStepView(selected: $draft.interests) {
                path.append(.mbti)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .mbti:
                    MBTIStepView(selected: $draft.mbti, interests: draft.interests) {
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
        let card = await model.completeOnboarding(
            nickname: draft.nickname,
            tagline: draft.tagline,
            emoji: draft.emoji,
            interests: draft.interests,
            mbti: draft.mbti
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
