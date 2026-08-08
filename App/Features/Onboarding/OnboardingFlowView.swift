import Core
import DesignSystem
import SwiftUI

/// 온보딩 3단계: 관심사(최대 5) → 성향 2×2 → 닉네임·한 줄·이모지 원탭 → 카드 리빌.
/// ⚠️ 카피는 gyeop-prototype.html 부재로 gyeop-spec.md F1 기준 임시 확정 —
/// 프로토타입 파일이 커밋되면 그 카피로 교체할 것.
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
