import Foundation

/// 계정 삭제 흐름 — 로컬 SwiftData 전량 소거 + Keychain 토큰 삭제를 한 번에 묶는다.
/// App Store 심사 필수 항목(계정으로 가입했다면 앱 내 삭제 수단 필수).
public struct AccountDeletionService: Sendable {
    private let repository: SwiftDataGyeopRepository
    private let tokenStore: KeychainTokenStore

    public init(repository: SwiftDataGyeopRepository, tokenStore: KeychainTokenStore = KeychainTokenStore()) {
        self.repository = repository
        self.tokenStore = tokenStore
    }

    /// 실행 후 프로필·카드·겹 기록·Apple 토큰이 전부 사라져야 한다.
    public func deleteAccount() async throws {
        try await repository.deleteAllLocalData()
        try tokenStore.deleteToken()
    }
}
