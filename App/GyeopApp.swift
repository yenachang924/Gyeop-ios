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

    var body: some View {
        Group {
            switch model.stage {
            case .loading:
                ProgressView()
            case .onboarding:
                OnboardingFlowView()
            case .home:
                CollectionView()
            }
        }
        .task { await model.bootstrap() }
    }
}
