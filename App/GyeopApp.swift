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
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        // 단계가 바뀔 때 화면이 뚝 갈리던 것을 크로스페이드로 잇는다 (F50).
        // 계정 삭제 → 웰컴 복귀가 특히 거칠었다. 컨테이너 애니메이션 금지(F46)의
        // 안전한 예외다 — 이 Group은 언제나 자식이 **하나뿐**이라 재배치가 없다.
        .transition(.opacity)
        .animation(reduceMotion ? nil : DS.Motion.settle, value: model.stage)
        .task { await model.bootstrap() }
    }
}
