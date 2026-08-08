import AppClipKit
import Core
import SwiftUI

/// 클립 온보딩 3단계 — 본앱 뷰(InterestsStepView·StyleStepView·ProfileStepView)를
/// **소스 공유로 그대로 재사용**한다 (project.yml GyeopClip sources 참조).
/// 본앱 OnboardingFlowView와 다른 점은 완주 후 목적지뿐이다: 리빌 push 대신
/// ClipModel이 `card` 단계로 넘어가 클립 레인(맞대기)이 이어진다.
struct ClipOnboardingFlowView: View {
    let model: ClipModel

    @State private var path: [Step] = []
    @State private var draft = OnboardingDraft()

    enum Step: Hashable {
        case style
        case profile
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
                }
            }
        }
    }

    private func createCard() async {
        guard let style = draft.style else { return }
        await model.completeOnboarding(
            nickname: draft.nickname,
            tagline: draft.tagline,
            emoji: draft.emoji,
            interests: draft.interests,
            style: style
        )
    }
}
