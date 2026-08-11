import Core
import Foundation
import SwiftData

/// "내 프로필" 저장 스키마 — 사용자 계정당 항상 1건(싱글턴)이다.
@Model
final class UserProfileEntity {
    @Attribute(.unique) var id: String
    var nickname: String
    var tagline: String
    var emoji: String
    var interests: [String]
    /// MBTI 4글자 코드 — 건너뛴 경우 빈 문자열 (F55, 성향 energy/venue를 대체).
    var mbtiRaw: String = ""
    var createdAt: Date

    init(profile: UserProfile) {
        id = profile.id
        nickname = profile.nickname
        tagline = profile.tagline
        emoji = profile.emoji
        interests = profile.interests
        mbtiRaw = profile.mbti?.code ?? ""
        createdAt = profile.createdAt
    }

    func update(with profile: UserProfile) {
        id = profile.id
        nickname = profile.nickname
        tagline = profile.tagline
        emoji = profile.emoji
        interests = profile.interests
        mbtiRaw = profile.mbti?.code ?? ""
        createdAt = profile.createdAt
    }

    func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            nickname: nickname,
            tagline: tagline,
            emoji: emoji,
            interests: interests,
            mbti: MBTI(code: mbtiRaw),
            createdAt: createdAt
        )
    }
}
