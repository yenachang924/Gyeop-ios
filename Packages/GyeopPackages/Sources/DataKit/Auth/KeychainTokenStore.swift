import Foundation
import Security

/// Keychain Services 직접 래핑. Sign in with Apple 토큰(identity token, user
/// identifier)을 저장·삭제한다 — 서드파티 래퍼 없이 CLAUDE.md 원칙대로 최소 의존.
public struct KeychainTokenStore: Sendable {
    public enum Error: Swift.Error, Equatable {
        case unexpectedStatus(OSStatus)
        case encodingFailed
    }

    private let service: String
    private let account: String

    public init(service: String = "com.gyeop.app.auth", account: String = "appleIDToken") {
        self.service = service
        self.account = account
    }

    /// 기존 값이 있으면 덮어쓴다.
    public func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { throw Error.encodingFailed }
        SecItemDelete(baseQuery() as CFDictionary)

        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw Error.unexpectedStatus(status) }
    }

    /// 저장된 값이 없으면 `nil`.
    public func loadToken() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw Error.unexpectedStatus(status) }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw Error.encodingFailed
        }
        return token
    }

    /// 없는 항목을 지워도 에러가 아니다(idempotent) — 계정 삭제 흐름에서 그대로 호출된다.
    public func deleteToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Error.unexpectedStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
