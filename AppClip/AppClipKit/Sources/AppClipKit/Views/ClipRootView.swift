import SwiftUI

/// 클립 레인 라우터 — `docs/navigation-map.md` §1과 1:1. 얇은 Xcode 앱 타깃
/// (../App/AppClipApp.swift)이 이 뷰 하나만 띄우고, 인보케이션 URL을
/// `model.receive(invocationURL:)`로 흘려보낸다.
///
/// 온보딩 3단계는 본앱 뷰(App/Features/Onboarding/*)를 클립 타깃이 소스 공유로
/// 재사용하므로, 이 패키지에서는 그릴 수 없다 — `onboarding` 클로저로 주입받는다.
public struct ClipRootView<Onboarding: View>: View {
    let model: ClipModel
    @ViewBuilder private let onboarding: () -> Onboarding

    public init(model: ClipModel, @ViewBuilder onboarding: @escaping () -> Onboarding) {
        self.model = model
        self.onboarding = onboarding
    }

    public var body: some View {
        Group {
            switch model.stage {
            case .reception:
                ClipReceptionView(inviterNickname: model.inviterNickname) {
                    model.beginOnboarding()
                }
            case .onboarding:
                onboarding()
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
                ClipKeepView(myCard: model.myCard, record: record) {
                    model.declineInstall()
                }
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
    private var stageKey: String {
        switch model.stage {
        case .reception: "reception"
        case .onboarding: "onboarding"
        case .card: "card"
        case .bump: "bump"
        case .overlap: "overlap"
        case .keep: "keep"
        case .done: "done"
        case .failed: "failed"
        }
    }
}
