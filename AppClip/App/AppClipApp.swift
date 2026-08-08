import AppClipKit
import SwiftUI

/// GyeopClip 앱 타깃의 유일한 진입점. 로직은 전부 AppClipKit(로컬 패키지)에 있고
/// 이 파일은 인보케이션 URL을 모델로 흘려보내는 배선만 한다.
///
/// 타깃 자체는 아직 project.yml에 연결돼 있지 않다 — 활성화 절차는
/// AppClip/README.md 참조 (S1/S6 소관, Developer Program 세팅 후).
@main
struct GyeopClipApp: App {
    @State private var model = ClipModel.live()

    var body: some Scene {
        WindowGroup {
            ClipRootView(model: model)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    model.receive(invocationURL: url)
                }
                .onOpenURL { url in
                    model.receive(invocationURL: url)
                }
        }
    }
}
