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

        let service = AccountDeletionService(repository: repo, tokenStore: tokenStore)
        try await service.deleteAccount()

        #expect(try await repo.myProfile() == nil)
        #expect(try await repo.myCard() == nil)
        #expect(try await repo.gyeops().isEmpty)
        #expect(try tokenStore.loadToken() == nil)
    }
}
