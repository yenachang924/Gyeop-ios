import Core
import Foundation
import SwiftData

/// "내 카드" 저장 스키마 — 싱글턴(가장 최근 저장분만 유지).
@Model
final class MyCardEntity {
    @Attribute(.unique) var ownerID: String
    var seed: String
    var nickname: String
    var tagline: String
    var emoji: String
    var interests: [String]
    /// MBTI 4글자 코드 — 건너뛴 경우 빈 문자열 (F55, 성향 energy/venue를 대체).
    var mbtiRaw: String = ""
    var version: Int
    var createdAt: Date

    init(card: CardSnapshot) {
        ownerID = card.ownerID
        seed = card.seed
        nickname = card.nickname
        tagline = card.tagline
        emoji = card.emoji
        interests = card.interests
        mbtiRaw = card.mbti?.code ?? ""
        version = card.version
        createdAt = card.createdAt
    }

    func update(with card: CardSnapshot) {
        ownerID = card.ownerID
        seed = card.seed
        nickname = card.nickname
        tagline = card.tagline
        emoji = card.emoji
        interests = card.interests
        mbtiRaw = card.mbti?.code ?? ""
        version = card.version
        createdAt = card.createdAt
    }

    func toDomain() -> CardSnapshot {
        CardSnapshot(
            ownerID: ownerID,
            seed: seed,
            nickname: nickname,
            tagline: tagline,
            emoji: emoji,
            interests: interests,
            mbti: MBTI(code: mbtiRaw),
            version: version,
            createdAt: createdAt
        )
    }
}
