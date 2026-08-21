import Foundation
import Testing
@testable import Core

@Suite("ProfileInput")
struct ProfileInputTests {
    @Test("accepts and normalizes valid profile input")
    func normalizesValidInput() throws {
        let input = try ProfileInput(
            nickname: " Ana ",
            currentStatus: " Building an iOS app ",
            emoji: "🌱",
            interests: [" AI ", "UX/UI", " Development "],
            mbti: MBTI(code: "INTJ")
        )

        #expect(input.nickname == "Ana")
        #expect(input.currentStatus == "Building an iOS app")
        #expect(input.emoji == "🌱")
        #expect(input.interests == ["AI", "UX/UI", "Development"])
        #expect(input.mbti == MBTI(code: "INTJ"))
    }

    @Test("rejects an empty nickname")
    func rejectsEmptyNickname() {
        #expect(throws: ProfileInputError.emptyNickname) { try makeInput(nickname: " \n ") }
    }

    @Test("rejects an empty current status")
    func rejectsEmptyCurrentStatus() {
        #expect(throws: ProfileInputError.emptyCurrentStatus) { try makeInput(currentStatus: "\t ") }
    }

    @Test("rejects an invalid emoji")
    func rejectsInvalidEmoji() {
        #expect(throws: ProfileInputError.invalidEmoji) { try makeInput(emoji: "🌱🌷") }
    }

    @Test(arguments: [[], ["AI"], ["AI", "Development"], ["AI", "UX/UI", "Development", "Games"]])
    func rejectsWrongInterestCount(_ interests: [String]) {
        #expect(throws: ProfileInputError.interestCount(expected: 3)) { try makeInput(interests: interests) }
    }

    @Test("rejects duplicate interests after trimming")
    func rejectsDuplicateInterestsAfterTrimming() {
        #expect(throws: ProfileInputError.duplicateInterest) {
            try makeInput(interests: ["AI", " AI ", "Development"])
        }
    }

    @Test("rejects an interest that is empty after trimming")
    func rejectsEmptyInterestAfterTrimming() {
        #expect(throws: ProfileInputError.emptyInterest) {
            try makeInput(interests: ["AI", " \n ", "Development"])
        }
    }

    @Test("rejects a 41-character current status")
    func rejectsLongCurrentStatus() {
        #expect(throws: ProfileInputError.currentStatusTooLong(maximum: 40)) {
            try makeInput(currentStatus: String(repeating: "a", count: 41))
        }
    }

    @Test("exposes current status aliases and defaults last update time")
    func exposesCompatibilityAliases() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let profile = UserProfile(id: "profile-1", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["AI", "UX/UI", "Development"], mbti: nil, createdAt: createdAt)
        let card = CardSnapshot(ownerID: "profile-1", seed: "seed", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["AI", "UX/UI", "Development"], mbti: nil, version: 1, createdAt: createdAt)

        #expect(profile.currentStatus == "Building an iOS app")
        #expect(profile.lastUpdatedAt == createdAt)
        #expect(card.currentStatus == "Building an iOS app")
    }

    @Test("decodes a legacy profile without an updated-at value")
    func decodesLegacyProfileWithCreatedAtFallback() throws {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let legacyProfile = LegacyUserProfile(id: "profile-1", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["AI", "UX/UI", "Development"], mbti: nil, createdAt: createdAt)

        let data = try JSONEncoder().encode(legacyProfile)
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(profile.updatedAt == nil)
        #expect(profile.lastUpdatedAt == createdAt)
    }

    private func makeInput(nickname: String = "Ana", currentStatus: String = "Building an iOS app", emoji: String = "🌱", interests: [String] = ["AI", "UX/UI", "Development"]) throws -> ProfileInput {
        try ProfileInput(nickname: nickname, currentStatus: currentStatus, emoji: emoji, interests: interests, mbti: nil)
    }
}

private struct LegacyUserProfile: Codable {
    let id: String
    let nickname: String
    let tagline: String
    let emoji: String
    let interests: [String]
    let mbti: MBTI?
    let createdAt: Date
}
