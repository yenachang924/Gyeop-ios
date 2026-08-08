#if canImport(StoreKit) && canImport(UIKit)
import StoreKit
import SwiftUI
import UIKit

/// SKOverlay 브릿지. **교환이 완료된 뒤에만** 호출한다 — 설치 전에 먼저 값을 보여주고
/// 나서야 설치를 제안한다는 게 이 제품의 핵심 주장이라, 호출 시점은 ClipModel.stage가
/// `.suggestingInstall`로 넘어간 뒤로 뷰 계층에서 강제한다 (아래 SwiftUI 모디파이어 참고).
@MainActor
public enum AppStoreOverlayPresenter {
    public static func presentInstallSuggestion(in scene: UIWindowScene?) {
        guard let scene else {
            ClipLog.flow.error("SKOverlay 제시 실패 — UIWindowScene 없음")
            return
        }
        let configuration = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: configuration)
        overlay.present(in: scene)
    }
}

/// `view.window?.windowScene`을 얻기 위한 최소 UIViewControllerRepresentable 브릿지.
/// SwiftUI는 UIWindowScene을 직접 노출하지 않는다.
private struct SceneAccessor: UIViewControllerRepresentable {
    let onScene: (UIWindowScene?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        DispatchQueue.main.async {
            onScene(controller.view.window?.windowScene)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private struct AppStoreOverlayModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content.background(
            SceneAccessor { scene in
                guard isPresented else { return }
                AppStoreOverlayPresenter.presentInstallSuggestion(in: scene)
            }
        )
    }
}

extension View {
    /// `isPresented`가 true인 프레임에서만 SKOverlay 설치 제안을 띄운다.
    public func appClipInstallSuggestion(isPresented: Bool) -> some View {
        modifier(AppStoreOverlayModifier(isPresented: isPresented))
    }
}
#else
import SwiftUI

extension View {
    /// StoreKit/UIKit이 없는 플랫폼(예: `swift test`의 macOS 호스트) 빌드용 무동작 폴백.
    public func appClipInstallSuggestion(isPresented: Bool) -> some View {
        self
    }
}
#endif
