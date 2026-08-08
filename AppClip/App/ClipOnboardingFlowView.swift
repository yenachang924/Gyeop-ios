import AppClipKit
import Core
import SwiftUI

/// 클립 레인 입구 — `clip`(카드 수신)을 NavigationStack 루트로 두고 온보딩 3단계를
/// push로 잇는다. 그래서 `interests`에서 뒤로 스와이프하면 시스템 제스처로 `clip`에
/// 돌아간다 (navigation-map §1-2). 온보딩 뷰(InterestsStepView·StyleStepView·
/// ProfileStepView)는 본앱 뷰를 **소스 공유로 그대로 재사용**한다 (project.yml
/// GyeopClip sources 참조). 본앱 OnboardingFlowView와 다른 점은 완주 후 목적지뿐이다:
/// 리빌 push 대신 ClipModel이 `card` 단계로 넘어가 클립 레인(맞대기)이 이어진다.
struct ClipOnboardingFlowView: View {
    let model: ClipModel

    @State private var path: [Step] = []
    @State private var draft = OnboardingDraft()

    enum Step: Hashable {
        case interests
        case style
        case profile
    }

    var body: some View {
        NavigationStack(path: $path) {
            ClipReceptionView(inviterNickname: model.inviterNickname) {
                model.beginOnboarding()
                path.append(.interests)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .interests:
                    InterestsStepView(selected: $draft.interests) {
                        path.append(.style)
                    }
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
        .onChange(of: path) { _, newPath in
            // `interests` 뒤로 스와이프로 루트까지 pop되면 단계도 `clip`으로 되돌린다 (§1-2)
            if newPath.isEmpty {
                model.backToReception()
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
