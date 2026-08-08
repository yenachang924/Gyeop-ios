import AppClipKit
import DesignSystem
import SwiftUI

/// GyeopClip 앱 타깃의 진입점. 레인 라우팅은 AppClipKit(ClipRootView),
/// 실구현 조립은 ClipAssembly, 온보딩 3단계는 본앱 뷰 소스 공유 — 이 파일은
/// 인보케이션 URL을 모델로 흘려보내는 배선만 한다.
@main
struct GyeopClipApp: App {
    @State private var model = ClipModel.live()

    var body: some Scene {
        WindowGroup {
            ClipRootView(model: model) {
                ClipOnboardingFlowView(model: model)
            }
            .tint(DS.Palette.accent)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else { return }
                model.receive(invocationURL: url)
            }
            .onOpenURL { url in
                model.receive(invocationURL: url)
            }
            .task {
                #if DEBUG
                // Xcode 없이 simctl로 띄울 때도 인보케이션을 주입할 수 있게
                // (`SIMCTL_CHILD__XCAppClipURL=…`) 환경 변수를 직접 읽는 폴백.
                // Xcode 실행 경로(NSUserActivity)와 겹쳐도 receive는 같은 URL 재파싱이라 무해하다.
                if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                   let url = URL(string: raw) {
                    model.receive(invocationURL: url)
                }
                #endif
            }
        }
    }
}
