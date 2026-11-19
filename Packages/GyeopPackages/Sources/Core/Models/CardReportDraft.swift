import Foundation

/// 사용자가 내용을 확인하고 메일 앱에서 직접 전송하는 초안. 전송 동작은 수행하지 않는다.
public struct CardReportDraft: Sendable {
    public enum Error: Swift.Error, Equatable {
        case emptyReason
        case reasonTooLong
        case invalidDraft
    }

    public static let supportEmail = "yenachang924@gmail.com"
    public static let maximumReasonLength = 1_000
    public let body: String
    public let mailtoURL: URL

    public init(card: CardSnapshot, reason: String) throws {
        let cleanReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanReason.isEmpty else { throw Error.emptyReason }
        guard cleanReason.count <= Self.maximumReasonLength else { throw Error.reasonTooLong }
        body = """
        겹 카드 신고

        신고 사유:
        \(cleanReason)

        신고 대상 카드:
        닉네임: \(card.nickname)
        지금의 나: \(card.currentStatus)
        로컬 사용자 ID: \(card.ownerID)

        이 내용은 사용자가 메일 앱에서 확인 후 직접 전송합니다.
        """
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "겹 카드 신고"),
            URLQueryItem(name: "body", value: body),
        ]
        guard let url = components.url else { throw Error.invalidDraft }
        mailtoURL = url
    }
}
