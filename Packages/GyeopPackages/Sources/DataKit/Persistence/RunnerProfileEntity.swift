import Core
import Foundation
import SwiftData

/// "내 프로필" 저장 스키마 — 러너 계정당 항상 1건(싱글턴)이다.
@Model
final class RunnerProfileEntity {
    @Attribute(.unique) var id: String
    var nickname: String
    var tagline: String
    var emoji: String
    var interests: [String]
    var energyRaw: String
    var venueRaw: String
    var createdAt: Date

    init(profile: RunnerProfile) {
        id = profile.id
        nickname = profile.nickname
        tagline = profile.tagline
        emoji = profile.emoji
        interests = profile.interests
        energyRaw = profile.leisureStyle.energy.rawValue
        venueRaw = profile.leisureStyle.venue.rawValue
        createdAt = profile.createdAt
    }

    func update(with profile: RunnerProfile) {
        id = profile.id
        nickname = profile.nickname
        tagline = profile.tagline
        emoji = profile.emoji
        interests = profile.interests
        energyRaw = profile.leisureStyle.energy.rawValue
        venueRaw = profile.leisureStyle.venue.rawValue
        createdAt = profile.createdAt
    }

    func toDomain() -> RunnerProfile {
        RunnerProfile(
            id: id,
            nickname: nickname,
            tagline: tagline,
            emoji: emoji,
            interests: interests,
            leisureStyle: LeisureStyle(
                energy: LeisureStyle.Energy(rawValue: energyRaw) ?? .calm,
                venue: LeisureStyle.Venue(rawValue: venueRaw) ?? .indoor
            ),
            createdAt: createdAt
        )
    }
}
