import Core
import DesignSystem
import SwiftUI

@main
struct GyeopApp: App {
    @State private var model = AppModel.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(DS.Palette.accent)
                // 2026-08-08 디자인 QA 세션: 제품 결정으로 접근성 확대 범위(AX1~5)를 앱 전체에서
                // 뺀다 — CLAUDE.md "Dynamic Type 대응" 원칙의 명시적 예외. 사용자 직접 지시.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch model.stage {
            case .loading:
                ProgressView()
            case .signIn:
                WelcomeView()
            case .onboarding:
                OnboardingFlowView()
            case .home:
                CollectionView()
            }
        }
        .task { await model.bootstrap() }
    }
}
