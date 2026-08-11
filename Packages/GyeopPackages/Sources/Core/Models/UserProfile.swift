import Foundation

/// 사용자 본인 프로필. 온보딩 3단계(관심사 → MBTI → 닉네임·한 줄·이모지)의 결과물이며
/// 카드 생성(`CardGenerating`)의 유일한 입력이다.
public struct UserProfile: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public var nickname: String
    /// 한 줄 소개
    public var tagline: String
    /// 원탭으로 고른 대표 이모지
    public var emoji: String
    /// 관심사 이름 (최대 5개 — `Self.maxInterests`)
    public var interests: [String]
    /// MBTI — 건너뛸 수 있다 (F55). nil이면 카드 뒷면에 표기가 없다.
    public var mbti: MBTI?
    public var createdAt: Date

    public static let maxInterests = 5

    public init(
        id: String,
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        mbti: MBTI?,
        createdAt: Date
    ) {
        self.id = id
        self.nickname = nickname
        self.tagline = tagline
        self.emoji = emoji
        self.interests = interests
        self.mbti = mbti
        self.createdAt = createdAt
    }
}
