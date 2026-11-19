/// Apple 프레임워크의 응답을 앱 시작 동작으로 해석하는 순수 정책.
/// 사용자 식별자가 없는 기존 빌드는 로컬 데이터를 유지한 채 재인증한다.
public enum AppleCredentialLaunchPolicy {
    public enum Status: Sendable {
        case authorized
        case revoked
        case notFound
        case transferred
        case unavailable
    }

    public enum Decision: Sendable, Equatable {
        case restoreLocalData
        case reauthenticate
        case deleteLocalData
        case retry
    }

    public static func decision(for status: Status?) -> Decision {
        guard let status else { return .reauthenticate }
        switch status {
        case .authorized: return .restoreLocalData
        case .revoked, .notFound: return .deleteLocalData
        case .transferred: return .reauthenticate
        case .unavailable: return .retry
        }
    }
}
