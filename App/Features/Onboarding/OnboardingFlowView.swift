import Core
import DesignSystem
import SwiftUI

/// 온보딩 3단계: 관심사 3개 → MBTI(건너뛰기 가능) → 닉네임·지금의 나·이모지 → 카드 리빌.
/// 카피 기준은 카드 리디자인 라운드 시안(review/proposals/mbti-card-redesign.html).
struct OnboardingFlowView: View {
    @Environment(AppModel.self) private var model

    @State private var path: [Step] = []
    @State private var draft = OnboardingDraft.empty

    enum Step: Hashable {
        case mbti
        case profile
        case reveal(CardSnapshot)
    }

    var body: some View {
        NavigationStack(path: $path) {
            InterestsStepView(selected: interestsBinding) {
                path.append(.mbti)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .mbti:
                    MBTIStepView(selected: mbtiBinding, interests: draft.interests) {
                        path.append(.profile)
                    }
                case .profile:
                    ProfileStepView(draft: $draft) { input in
                        await createCard(input: input)
                    }
                case .reveal(let card):
                    CardRevealView(card: card)
                }
            }
        }
    }

    private var interestsBinding: Binding<[String]> {
        Binding(
            get: { draft.interests },
            set: { draft = draft.replacing(interests: $0) }
        )
    }

    private var mbtiBinding: Binding<MBTI?> {
        Binding(
            get: { draft.mbti },
            set: { draft = draft.replacing(mbti: $0) }
        )
    }

    private func createCard(input: ProfileInput) async -> Bool {
        guard let card = await model.completeOnboarding(input: input) else { return false }
        path.append(.reveal(card))
        return true
    }
}

#Preview {
    OnboardingFlowView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
