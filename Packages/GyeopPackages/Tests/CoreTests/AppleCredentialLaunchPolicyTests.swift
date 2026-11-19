import Testing
@testable import Core

@Suite("AppleCredentialLaunchPolicy")
struct AppleCredentialLaunchPolicyTests {
    @Test("사용자 식별자가 없는 기존 세션은 데이터를 유지하고 다시 로그인한다")
    func legacySessionRequiresAuthentication() {
        #expect(AppleCredentialLaunchPolicy.decision(for: nil) == .reauthenticate)
    }

    @Test("Apple이 확인한 상태만 세션 복원·삭제·재시도를 결정한다")
    func credentialStateDecisions() {
        #expect(AppleCredentialLaunchPolicy.decision(for: .authorized) == .restoreLocalData)
        #expect(AppleCredentialLaunchPolicy.decision(for: .revoked) == .deleteLocalData)
        #expect(AppleCredentialLaunchPolicy.decision(for: .notFound) == .deleteLocalData)
        #expect(AppleCredentialLaunchPolicy.decision(for: .transferred) == .reauthenticate)
        #expect(AppleCredentialLaunchPolicy.decision(for: .unavailable) == .retry)
    }
}
