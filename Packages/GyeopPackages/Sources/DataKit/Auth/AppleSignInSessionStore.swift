import Foundation

/// Apple이 인증 완료 시 제공한 식별자와 토큰. 토큰 본문을 해석하지 않는다.
public struct AppleSignInSession: Codable, Sendable, Equatable {
    public let userIdentifier: String
    public let identityToken: String

    public init(userIdentifier: String, identityToken: String) {
        self.userIdentifier = userIdentifier
        self.identityToken = identityToken
    }
}

/// 두 자격 값을 하나의 Keychain 항목으로 보관해 서로 다른 세션이 섞이지 않게 한다.
public struct AppleSignInSessionStore: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidCredential
        case invalidStoredSession
    }

    private let store: KeychainTokenStore

    public init(store: KeychainTokenStore = KeychainTokenStore(account: "appleSignInSession")) {
        self.store = store
    }

    public func save(_ session: AppleSignInSession) throws {
        guard isValid(session) else { throw Error.invalidCredential }
        let data = try JSONEncoder().encode(session)
        guard let encoded = String(data: data, encoding: .utf8) else {
            throw Error.invalidCredential
        }
        try store.save(encoded)
    }

    public func load() throws -> AppleSignInSession? {
        guard let encoded = try store.loadToken() else { return nil }
        guard let data = encoded.data(using: .utf8) else { throw Error.invalidStoredSession }
        do {
            let session = try JSONDecoder().decode(AppleSignInSession.self, from: data)
            guard isValid(session) else { throw Error.invalidStoredSession }
            return session
        } catch {
            throw Error.invalidStoredSession
        }
    }

    public func delete() throws {
        try store.deleteToken()
    }

    private func isValid(_ session: AppleSignInSession) -> Bool {
        !session.userIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !session.identityToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
