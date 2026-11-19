import Core
import Foundation
import Testing
@testable import DataKit

@Suite("AccountDeletionService")
struct AccountDeletionServiceTests {
    @Test("계정 삭제는 로컬 데이터와 Keychain 토큰을 모두 지운다")
    func deleteAccountWipesDataAndToken() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        try await repo.record(MockData.sampleGyeops[0])

        let tokenStore = KeychainTokenStore(
            service: "com.gyeop.app.tests.auth", account: "test-\(UUID().uuidString)"
        )
        try tokenStore.save("dummy-identity-token")
        let sessionStore = AppleSignInSessionStore(store: KeychainTokenStore(
            service: "com.gyeop.app.tests.auth", account: "session-\(UUID().uuidString)"
        ))
        try sessionStore.save(AppleSignInSession(
            userIdentifier: "apple-user", identityToken: "dummy-identity-token"
        ))

        let blockedUserStore = BlockedUserStore(inMemory: true)
        try await blockedUserStore.block(ownerID: "blocked-user")
        let service = AccountDeletionService(
            repository: repo, tokenStore: tokenStore, sessionStore: sessionStore,
            blockedUserStore: blockedUserStore
        )
        try await service.deleteAccount()

        #expect(try await repo.myProfile() == nil)
        #expect(try await repo.myCard() == nil)
        #expect(try await repo.gyeops().isEmpty)
        #expect(try tokenStore.loadToken() == nil)
        #expect(try sessionStore.load() == nil)
        #expect(try await blockedUserStore.list().isEmpty)
    }
}
