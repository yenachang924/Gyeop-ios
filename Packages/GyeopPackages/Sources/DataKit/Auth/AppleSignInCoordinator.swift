import AuthenticationServices
import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Sign in with Apple 성공 결과. `identityToken`은 호출부가 `KeychainTokenStore`로
/// 저장한다 — 저장 책임은 코디네이터가 아니라 조립부(App)에 있다.
public struct AppleSignInResult: Sendable, Equatable {
    public let userIdentifier: String
    public let identityToken: String
    public let email: String?
    public let fullName: String?
}

public enum AppleSignInError: Swift.Error, Equatable {
    case missingIdentityToken
    case invalidCredential
    case authorization(String)
}

/// `ASAuthorizationController` 델리게이트 콜백을 async/await로 감싼 얇은 래퍼.
///
/// 실기기·시뮬레이터에서 Apple ID로 직접 확인해야 하는 항목이라 자동 테스트는
/// 없다 — `docs/device-required.md` 참조.
@MainActor
public final class AppleSignInCoordinator: NSObject {
    private var continuation: CheckedContinuation<AppleSignInResult, Swift.Error>?
    private var activeController: ASAuthorizationController?

    override public init() {
        super.init()
    }

    public func signIn() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            activeController = controller
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<AppleSignInResult, Swift.Error>) {
        activeController = nil
        continuation?.resume(with: result)
        continuation = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(.failure(AppleSignInError.invalidCredential))
            return
        }
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(AppleSignInError.missingIdentityToken))
            return
        }
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        finish(.success(AppleSignInResult(
            userIdentifier: credential.user,
            identityToken: token,
            email: credential.email,
            fullName: fullName.isEmpty ? nil : fullName
        )))
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
        finish(.failure(AppleSignInError.authorization(error.localizedDescription)))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
        #elseif os(macOS)
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #endif
    }
}
