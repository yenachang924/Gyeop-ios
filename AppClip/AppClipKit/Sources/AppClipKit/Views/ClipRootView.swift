import SwiftUI

/// 클립 레인 라우터 — `docs/navigation-map.md` §1과 1:1. 얇은 Xcode 앱 타깃
/// (../App/AppClipApp.swift)이 이 뷰 하나만 띄우고, 인보케이션 URL을
/// `model.receive(invocationURL:)`로 흘려보낸다.
///
/// `clip`(카드 수신)과 온보딩 3단계는 클립 타깃이 NavigationStack 하나로 조립해
/// `entry` 클로저로 주입한다 (../App/ClipOnboardingFlowView.swift) — 수신을 루트로,
/// 온보딩을 push로 이어야 `interests` 뒤로 스와이프 → `clip`(§1-2)이 시스템 제스처로
/// 성립하고, 온보딩 뷰(본앱 App/Features/Onboarding/*)는 소스 공유라 이 패키지에서
/// 그릴 수 없기 때문이다.
public struct ClipRootView<Entry: View>: View {
    let model: ClipModel
    @ViewBuilder private let entry: () -> Entry

    public init(model: ClipModel, @ViewBuilder entry: @escaping () -> Entry) {
        self.model = model
        self.entry = entry
    }

    public var body: some View {
        Group {
            switch model.stage {
            case .reception, .onboarding:
                entry()
            case .card(let card):
                ClipMyCardView(card: card, inviterNickname: model.inviterNickname) {
                    Task { await model.startBump() }
                }
            case .bump:
                ClipBumpView()
            case .overlap(let record):
                ClipOverlapView(myCard: model.myCard, record: record) {
                    model.acceptCard()
                }
            case .keep(let record):
                ClipKeepView(
                    myCard: model.myCard,
                    record: record,
                    onLater: { model.declineInstall() },
                    onInstallDismissed: { model.finishInstallSuggestion() }
                )
            case .done(let record):
                ClipDoneView(myCard: model.myCard, record: record)
            case .failed(let failure):
                ClipFailureView(failure: failure) {
                    await model.retryExchange()
                }
            }
        }
        .animation(.default, value: stageKey)
    }

    /// switch case 자체는 Equatable 비교가 안 돼 애니메이션 키로 못 쓰니, 케이스 이름만 뽑는다.
    /// reception↔온보딩은 한 NavigationStack 안의 push/pop이라 같은 키다.
    private var stageKey: String {
        switch model.stage {
        case .reception, .onboarding: "entry"
        case .card: "card"
        case .bump: "bump"
        case .overlap: "overlap"
        case .keep: "keep"
        case .done: "done"
        case .failed: "failed"
        }
    }
}
