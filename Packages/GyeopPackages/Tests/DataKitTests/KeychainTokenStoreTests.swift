import Foundation
import Testing
@testable import DataKit

@Suite("KeychainTokenStore")
struct KeychainTokenStoreTests {
    /// 테스트마다 계정을 분리해 병렬 실행 시 서로 간섭하지 않게 한다.
    private func makeStore() -> KeychainTokenStore {
        KeychainTokenStore(service: "com.gyeop.app.tests.auth", account: "test-\(UUID().uuidString)")
    }

    @Test("저장한 토큰을 그대로 읽는다")
    func saveAndLoad() throws {
        let store = makeStore()
        defer { try? store.deleteToken() }

        try store.save("identity-token-abc")

        #expect(try store.loadToken() == "identity-token-abc")
    }

    @Test("저장 전에는 nil")
    func loadBeforeSaveReturnsNil() throws {
        #expect(try makeStore().loadToken() == nil)
    }

    @Test("재저장은 이전 값을 덮어쓴다")
    func saveOverwrites() throws {
        let store = makeStore()
        defer { try? store.deleteToken() }

        try store.save("first")
        try store.save("second")

        #expect(try store.loadToken() == "second")
    }

    @Test("삭제 후에는 nil이고, 이미 지운 항목을 다시 지워도 에러가 아니다")
    func deleteIsIdempotent() throws {
        let store = makeStore()
        try store.save("to-delete")

        try store.deleteToken()
        #expect(try store.loadToken() == nil)
        try store.deleteToken()
    }
}
