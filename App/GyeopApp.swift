import AuthenticationServices
import Core
import DesignSystem
import Foundation
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
    @AppStorage(RevocationStorage.pendingKey) private var pendingCredentialRevocation = false
    @State private var startupInProgress = true
    @State private var revocationPhase = RevocationPhase.idle

    var body: some View {
        Group {
            if revocationPhase == .credentialCheckFailed {
                credentialCheckFailure
            } else if !pendingCredentialRevocation && revocationPhase == .idle {
                appContent
            } else if revocationPhase == .failed {
                ContentUnavailableView {
                    Label("Apple 로그인 연결이 해제됐어요", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("이 기기의 데이터를 정리하지 못했어요. 다시 시도해 주세요.")
                } actions: {
                    Button("다시 시도") {
                        Task { await deleteRevokedCredentials() }
                    }
                    .accessibilityIdentifier("auth.revocation.retry")
                }
            } else {
                ProgressView(revocationPhase == .checkingCredentials
                    ? "Apple 로그인 상태를 확인하고 있어요"
                    : "로그인 정보와 데이터를 정리하고 있어요")
            }
        }
        // 단계가 바뀔 때 화면이 뚝 갈리던 것을 크로스페이드로 잇는다 (F50).
        // 계정 삭제 → 웰컴 복귀가 특히 거칠었다. 컨테이너 애니메이션 금지(F46)의
        // 안전한 예외다 — 이 Group은 언제나 자식이 **하나뿐**이라 재배치가 없다.
        .transition(.opacity)
        .animation(reduceMotion ? nil : DS.Motion.settle, value: model.stage)
        .task { await prepareSession() }
        .onReceive(NotificationCenter.default.publisher(
            for: ASAuthorizationAppleIDProvider.credentialRevokedNotification
        )) { _ in
            guard revocationPhase != .deleting && revocationPhase != .failed else { return }
            model.invalidateAuthentication()
            pendingCredentialRevocation = true
            revocationPhase = .pending
            if !startupInProgress {
                Task { await deleteRevokedCredentials() }
            }
        }
    }

    private func prepareSession() async {
        guard revocationPhase != .checkingCredentials && revocationPhase != .deleting else { return }
        startupInProgress = true
        defer { startupInProgress = false }
        if pendingCredentialRevocation {
            revocationPhase = .pending
            await deleteRevokedCredentials()
            return
        }
        revocationPhase = .checkingCredentials
        do {
            let decision = try await model.credentialLaunchDecision()
            if pendingCredentialRevocation {
                revocationPhase = .pending
                await deleteRevokedCredentials()
                return
            }
            try await applyLaunchDecision(decision)
        } catch {
            if pendingCredentialRevocation {
                revocationPhase = .pending
                await deleteRevokedCredentials()
            } else {
                Log.sync.error("Apple 로그인 상태 확인 실패: \(error)")
                revocationPhase = .credentialCheckFailed
            }
        }
    }

    private func applyLaunchDecision(_ decision: AppleCredentialLaunchPolicy.Decision) async throws {
        switch decision {
        case .restoreLocalData:
            try await model.bootstrap()
            if pendingCredentialRevocation {
                revocationPhase = .pending
                await deleteRevokedCredentials()
            } else {
                revocationPhase = .idle
            }
        case .reauthenticate:
            model.returnToEntry()
            revocationPhase = .idle
        case .deleteLocalData:
            pendingCredentialRevocation = true
            revocationPhase = .pending
            await deleteRevokedCredentials()
        case .retry:
            revocationPhase = .credentialCheckFailed
        }
    }

    private var credentialCheckFailure: some View {
        ContentUnavailableView {
            Label("저장 정보와 로그인을 확인하지 못했어요", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("연결 상태를 확인하고 다시 시도해 주세요. 기기의 데이터는 삭제하지 않았어요.")
        } actions: {
            Button("다시 시도") {
                Task { await prepareSession() }
            }
            .accessibilityIdentifier("auth.credentialCheck.retry")
        }
    }

    @ViewBuilder
    private var appContent: some View {
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

    /// Bootstrap 완료 후 직렬로 삭제한다. 실패한 동안 정상 화면은 노출하지 않는다.
    private func deleteRevokedCredentials() async {
        guard revocationPhase == .pending || revocationPhase == .failed else { return }
        revocationPhase = .deleting
        guard await model.deleteAccount() else {
            revocationPhase = .failed
            return
        }
        model.returnToEntry()
        pendingCredentialRevocation = false
        revocationPhase = .idle
    }

    private enum RevocationStorage {
        static let pendingKey = "gyeop.pendingAppleCredentialRevocation"
    }

    private enum RevocationPhase: Equatable {
        case idle
        case checkingCredentials
        case credentialCheckFailed
        case pending
        case deleting
        case failed
    }
}
