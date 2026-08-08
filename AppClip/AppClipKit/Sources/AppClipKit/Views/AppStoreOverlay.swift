#if canImport(StoreKit) && canImport(UIKit)
import StoreKit
import SwiftUI
import UIKit

/// SKOverlay 브릿지. **`keep` 화면의 「전체 앱 받기」 탭에서만** 호출된다 —
/// 설치 전에 먼저 값을 보여주고 나서야 설치를 묻는 순서가 이 제품의 핵심 주장이라,
/// 이 모디파이어를 거는 뷰는 ClipKeepView 하나뿐이고, 그 뷰는 ClipStage.keep
/// (= 교환 완료 후)에서만 그려진다. 그 이전 화면 어디에도 설치 유도 UI가 없다.
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

    @State private var scene: UIWindowScene?

    func body(content: Content) -> some View {
        content
            .background(
                SceneAccessor { found in
                    scene = found
                    // 씬 확보 전에 이미 탭된 경우 (버튼이 매우 빨리 눌린 프레임)
                    if isPresented {
                        AppStoreOverlayPresenter.presentInstallSuggestion(in: found)
                    }
                }
            )
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    AppStoreOverlayPresenter.presentInstallSuggestion(in: scene)
                }
            }
    }
}

extension View {
    /// `isPresented`가 false→true로 바뀌는 프레임에 SKOverlay 설치 제안을 띄운다.
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
