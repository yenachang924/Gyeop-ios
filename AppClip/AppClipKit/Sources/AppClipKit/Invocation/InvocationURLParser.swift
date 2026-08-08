import Foundation

public enum InvocationParsingError: Error, Sendable, Equatable {
    /// 스킴이 지원 범위(https 유니버설 링크 · gyeop:// QR 폴백) 밖이다
    case unsupportedScheme
    /// 쿼리에 교환 토큰(`t`)이 없다
    case missingToken
}

/// 클립 인보케이션 URL 파서.
///
/// 지원 형태 (둘 다 같은 쿼리 스키마를 공유 — QR은 같은 유니버설 링크를 인코딩한 이미지일 뿐):
/// - `https://<associated-domain>/clip?t=<token>&n=<nickname>` (App Clip 카드 탭, 실제 도메인은 소유자 결정 — 지금은 자리 표시)
/// - `gyeop://clip?t=<token>&n=<nickname>` (커스텀 스킴 QR 폴백 — 링크가 아직 도메인에 연결되지 않은 개발 단계용)
public enum InvocationURLParser {
    private static let supportedSchemes: Set<String> = ["https", "gyeop"]

    public static func parse(_ url: URL) throws -> ClipInvocation {
        guard let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) else {
            throw InvocationParsingError.unsupportedScheme
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw InvocationParsingError.missingToken
        }
        let items = components.queryItems ?? []
        guard let token = items.first(where: { $0.name == "t" })?.value, !token.isEmpty else {
            throw InvocationParsingError.missingToken
        }
        let nickname = items.first(where: { $0.name == "n" })?.value?.isEmpty == false
            ? items.first(where: { $0.name == "n" })?.value
            : nil

        return ClipInvocation(exchangeToken: token, inviterNickname: nickname)
    }
}
