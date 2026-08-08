import SwiftUI

/// 클립 진입점 뷰. 얇은 Xcode 앱 타깃(../App/AppClipApp.swift)이 이 뷰 하나만 띄우고,
/// 인보케이션 URL을 `model.receive(invocationURL:)`로 흘려보낸다.
public struct ClipRootView: View {
    let model: ClipModel

    public init(model: ClipModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.stage {
            case .invocation:
                ProgressView()
            case .onboarding:
                ClipOnboardingView(inviterNickname: model.invocation?.inviterNickname) { nickname, tagline, emoji, interests, style in
                    await model.completeOnboarding(
                        nickname: nickname,
                        tagline: tagline,
                        emoji: emoji,
                        interests: interests,
                        style: style
                    )
                }
            case .exchanging:
                ClipExchangingView()
            case .suggestingInstall(let record):
                ClipInstallSuggestionView(myCard: model.myCard, record: record)
            case .failed(let failure):
                ClipFailureView(failure: failure) {
                    await model.retryExchange()
                }
            }
        }
        .animation(.default, value: isStageChangeKey)
    }

    /// switch case 자체는 Equatable 비교가 안 돼 애니메이션 키로 못 쓰니, 케이스 이름만 뽑는다.
    private var isStageChangeKey: String {
        switch model.stage {
        case .invocation: "invocation"
        case .onboarding: "onboarding"
        case .exchanging: "exchanging"
        case .suggestingInstall: "suggestingInstall"
        case .failed: "failed"
        }
    }
}
