import Foundation

/// 정체성 카드의 값 타입 스냅샷. 맞대기로 교환되는 데이터 단위이며,
/// `seed`가 같으면 비주얼도 픽셀 동일해야 한다 (결정적 렌더 — CardKit의 계약).
public struct CardSnapshot: Codable, Hashable, Sendable, Identifiable {
    /// 카드 소유 러너 ID (GyeopID 계산에 쓰인다)
    public let ownerID: String
    /// 프로필 입력에서 결정적으로 유도된 시드 (같은 입력 = 같은 시드 = 같은 카드)
    public let seed: String
    public let nickname: String
    public let tagline: String
    public let emoji: String
    public let interests: [String]
    /// MBTI — 카드 뒷면에 4글자로 실린다. 건너뛴 사용자는 nil (F55).
    public let mbti: MBTI?
    /// 카드 버전 (관심사가 바뀌면 카드가 "자라며" 버전이 올라간다)
    public let version: Int
    public let createdAt: Date

    public var id: String { seed }

    public init(
        ownerID: String,
        seed: String,
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        mbti: MBTI?,
        version: Int,
        createdAt: Date
    ) {
        self.ownerID = ownerID
        self.seed = seed
        self.nickname = nickname
        self.tagline = tagline
        self.emoji = emoji
        self.interests = interests
        self.mbti = mbti
        self.version = version
        self.createdAt = createdAt
    }

    /// 두 카드가 겹치는 관심사 — 맞대기 직후 하이라이트되어 첫 대화 소재가 된다.
    public func sharedInterests(with other: CardSnapshot) -> [String] {
        interests.filter { other.interests.contains($0) }
    }
}
