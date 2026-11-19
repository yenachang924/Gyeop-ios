import Foundation

/// 기기 내 게시·수신 경계의 기본 텍스트 필터. 신고와 사용자 차단을 대체하지 않는다.
/// 정해진 명백한 욕설·혐오·성적 학대·위협 표현을 검사하며 모든 유해 문맥을 판별하지는 못한다.
public enum ContentModerationPolicy {
    private static let maximumTextScalars = 4_096
    private static let maximumLegacyInterests = 5
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static let englishExpressions = [
        "fuck", "fucking", "fucker", "motherfucker", "asshole", "cunt",
        "nigger", "nigga", "faggot", "heil hitler", "white power",
        "child porn", "child sex", "rape you", "kill yourself"
    ]
    private static let koreanExpressions = [
        "씨발", "개새끼", "병신", "느금마", "니애미", "니엄마",
        "시발놈", "시발새끼", "시발년", "시발아", "아동포르노",
        "미성년자성매매", "강간", "성폭행", "죽여버릴", "자살해"
    ]
    private static let englishPatterns = englishExpressions.map { expression in
        let letters = expression.filter { !$0.isWhitespace }.map(String.init)
        return "(?<![\\p{L}\\p{N}])" + letters.joined(separator: "[\\W_]*")
            + "(?![\\p{L}\\p{N}])"
    }

    public static func isAllowed(text: String) -> Bool {
        guard text.unicodeScalars.count <= maximumTextScalars,
              !text.unicodeScalars.contains(where: isUnsafeControl)
        else { return false }
        let normalized = normalize(text)
        guard !normalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !englishPatterns.contains(where: {
            normalized.range(of: $0, options: .regularExpression) != nil
        }) else { return false }
        let compact = String(normalized.filter { $0.isLetter || $0.isNumber })
        guard !koreanExpressions.contains(where: compact.contains) else { return false }
        // 일반 명사 "시발점" 같은 단어 내부와 독립된 욕설을 구분한다.
        return normalized.range(
            of: "(?<![\\p{L}\\p{N}])시[\\W_]*발(?![\\p{L}\\p{N}])",
            options: .regularExpression
        ) == nil
    }

    public static func isAllowed(card: CardSnapshot) -> Bool {
        !card.ownerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isAllowed(
                nickname: card.nickname, currentStatus: card.currentStatus,
                emoji: card.emoji, interests: card.interests
            )
    }

    /// 이전 버전의 안전한 관심사 이름과 개수는 수신할 수 있다. 새 프로필의 카탈로그
    /// 및 정확히 3개라는 제약은 ProfileInput이 별도로 검사한다.
    public static func isAllowed(
        nickname: String, currentStatus: String, emoji: String, interests: [String]
    ) -> Bool {
        !interests.isEmpty && interests.count <= maximumLegacyInterests
            && ProfileInput.isEmoji(emoji)
            && ([nickname, currentStatus, emoji] + interests).allSatisfy { isAllowed(text: $0) }
    }

    private static func normalize(_ text: String) -> String {
        let folded = text.precomposedStringWithCompatibilityMapping.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: locale
        )
        return String(String.UnicodeScalarView(folded.unicodeScalars.filter {
            !$0.properties.isDefaultIgnorableCodePoint
        }))
    }

    private static func isUnsafeControl(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.generalCategory == .control && !scalar.properties.isWhitespace
    }
}
