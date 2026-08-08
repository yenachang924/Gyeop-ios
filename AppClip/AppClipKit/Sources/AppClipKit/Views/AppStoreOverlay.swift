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
    /// SKOverlay.delegate는 약한 참조라, 오버레이가 떠 있는 동안 우리가 붙잡아야 한다.
    private static var activeDelegate: OverlayDismissalDelegate?

    public static func presentInstallSuggestion(
        in scene: UIWindowScene?,
        onDismiss: @escaping () -> Void = {}
    ) {
        guard let scene else {
            ClipLog.flow.error("SKOverlay 제시 실패 — UIWindowScene 없음")
            return
        }
        let configuration = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: configuration)
        let delegate = OverlayDismissalDelegate {
            activeDelegate = nil
            onDismiss()
        }
        activeDelegate = delegate
        overlay.delegate = delegate
        overlay.present(in: scene)
    }
}

/// 오버레이가 닫힌 시점(= App Store 상호작용 완료)을 알려주는 최소 델리게이트.
/// SKOverlay 콜백은 메인 스레드로 온다 — @preconcurrency 준수로 격리를 보장받는다.
@MainActor
private final class OverlayDismissalDelegate: NSObject, @preconcurrency SKOverlayDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func storeOverlayDidFinishDismissal(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        onDismiss()
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
    let onDismiss: () -> Void

    @State private var scene: UIWindowScene?

    func body(content: Content) -> some View {
        content
            .background(
                SceneAccessor { found in
                    scene = found
                    // 씬 확보 전에 이미 탭된 경우 (버튼이 매우 빨리 눌린 프레임)
                    if isPresented {
                        AppStoreOverlayPresenter.presentInstallSuggestion(in: found, onDismiss: onDismiss)
                    }
                }
            )
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    AppStoreOverlayPresenter.presentInstallSuggestion(in: scene, onDismiss: onDismiss)
                }
            }
    }
}

extension View {
    /// `isPresented`가 false→true로 바뀌는 프레임에 SKOverlay 설치 제안을 띄우고,
    /// 오버레이가 닫히면(App Store 상호작용 완료) `onDismiss`를 부른다 — `keep` → `done`
    /// (navigation-map §1-8)은 이 콜백으로 성립한다.
    public func appClipInstallSuggestion(
        isPresented: Bool,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(AppStoreOverlayModifier(isPresented: isPresented, onDismiss: onDismiss))
    }
}
#else
import SwiftUI

extension View {
    /// StoreKit/UIKit이 없는 플랫폼(예: `swift test`의 macOS 호스트) 빌드용 무동작 폴백.
    public func appClipInstallSuggestion(
        isPresented: Bool,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        self
    }
}
#endif
