import Foundation
import Testing
@testable import DataKit

@Suite("AppleSignInSessionStore")
struct AppleSignInSessionStoreTests {
    private func makeStore() -> AppleSignInSessionStore {
        AppleSignInSessionStore(store: KeychainTokenStore(
            service: "com.gyeop.app.tests.auth", account: "session-\(UUID().uuidString)"
        ))
    }

    @Test("Apple 사용자 식별자와 토큰을 한 세션으로 저장하고 복원한다")
    func saveAndLoadSession() throws {
        let store = makeStore()
        defer { try? store.delete() }
        let session = AppleSignInSession(userIdentifier: "apple-user", identityToken: "identity-token")

        try store.save(session)

        #expect(try store.load() == session)
    }

    @Test("식별자 또는 토큰이 빈 세션은 저장하지 않는다")
    func rejectsEmptyCredentials() throws {
        let store = makeStore()
        #expect(throws: AppleSignInSessionStore.Error.invalidCredential) {
            try store.save(AppleSignInSession(userIdentifier: " ", identityToken: "token"))
        }
        #expect(throws: AppleSignInSessionStore.Error.invalidCredential) {
            try store.save(AppleSignInSession(userIdentifier: "user", identityToken: ""))
        }
        #expect(try store.load() == nil)
    }

    @Test("삭제 후 세션을 복원하지 않으며 반복 삭제가 가능하다")
    func deleteClearsSession() throws {
        let store = makeStore()
        try store.save(AppleSignInSession(userIdentifier: "user", identityToken: "token"))
        try store.delete()
        try store.delete()
        #expect(try store.load() == nil)
    }

    @Test("잘못된 저장값을 인증된 세션으로 해석하지 않는다")
    func rejectsCorruptStoredSession() throws {
        let keychain = KeychainTokenStore(
            service: "com.gyeop.app.tests.auth", account: "corrupt-\(UUID().uuidString)"
        )
        defer { try? keychain.deleteToken() }
        try keychain.save("not-a-session")
        let store = AppleSignInSessionStore(store: keychain)

        #expect(throws: AppleSignInSessionStore.Error.invalidStoredSession) {
            try store.load()
        }
    }
}
