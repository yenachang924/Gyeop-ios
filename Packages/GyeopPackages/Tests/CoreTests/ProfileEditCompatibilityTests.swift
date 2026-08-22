import Foundation
import Testing
@testable import Core

@Suite("Profile edit compatibility")
struct ProfileEditCompatibilityTests {
    @Test("mixed legacy interests retain only supported values in profile order")
    func sanitizesMixedLegacyInterests() {
        let sanitized = InterestCatalog.sanitizedSelection(
            from: ["연구", "legacy-community", "글쓰기"]
        )

        #expect(sanitized == ["연구", "글쓰기"])
    }

    @Test("Build 4 five-interest profiles retain only the first three supported values")
    func sanitizesFiveInterestProfile() {
        let sanitized = InterestCatalog.sanitizedSelection(
            from: ["디자인", "연구", "글쓰기", "테크", "사진"]
        )

        #expect(sanitized == ["디자인", "연구", "글쓰기"])
    }

    @Test("profile update preserves identity and creation date while advancing freshness and version")
    func makesProfileUpdateReplacement() throws {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let currentProfile = UserProfile(
            id: "user-existing",
            nickname: "Before",
            tagline: "Before status",
            emoji: "🌱",
            interests: ["연구", "글쓰기", "디자인"],
            mbti: MBTI(code: "INTJ"),
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let currentCard = MockCardGenerator().makeCard(from: currentProfile, version: 4)
        let input = try ProfileInput(
            nickname: "After",
            currentStatus: "After status",
            emoji: "🌷",
            interests: ["사진", "여행", "독서"],
            mbti: MBTI(code: "ENFP")
        )

        let update = ProfileUpdate.make(
            currentProfile: currentProfile,
            currentCard: currentCard,
            input: input,
            now: now,
            cardGenerator: MockCardGenerator()
        )

        #expect(update.profile.id == "user-existing")
        #expect(update.profile.createdAt == createdAt)
        #expect(update.profile.updatedAt == now)
        #expect(update.profile.nickname == "After")
        #expect(update.card.ownerID == "user-existing")
        #expect(update.card.createdAt == createdAt)
        #expect(update.card.version == 5)
        #expect(update.card.currentStatus == "After status")
        #expect(update.card.interests == input.interests)
    }
}
