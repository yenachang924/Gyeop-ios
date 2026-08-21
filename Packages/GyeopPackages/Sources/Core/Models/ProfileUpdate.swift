import Foundation

public struct ProfileUpdate: Sendable {
    public let profile: UserProfile
    public let card: CardSnapshot

    public static func make(
        currentProfile: UserProfile,
        currentCard: CardSnapshot,
        input: ProfileInput,
        now: Date,
        cardGenerator: any CardGenerating
    ) -> ProfileUpdate {
        let profile = UserProfile(
            id: currentProfile.id,
            nickname: input.nickname,
            tagline: input.currentStatus,
            emoji: input.emoji,
            interests: input.interests,
            mbti: input.mbti,
            createdAt: currentProfile.createdAt,
            updatedAt: now
        )
        return ProfileUpdate(
            profile: profile,
            card: cardGenerator.makeCard(from: profile, version: currentCard.version + 1)
        )
    }
}
