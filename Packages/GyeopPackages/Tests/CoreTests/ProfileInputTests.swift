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
            interests: [" 연구 ", "글쓰기", " 디자인 "],
            mbti: MBTI(code: "INTJ")
        )

        #expect(input.nickname == "Ana")
        #expect(input.currentStatus == "Building an iOS app")
        #expect(input.emoji == "🌱")
        #expect(input.interests == ["연구", "글쓰기", "디자인"])
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

    @Test(arguments: ["A", "1"])
    func rejectsSingleNonEmojiGraphemes(_ value: String) {
        #expect(throws: ProfileInputError.invalidEmoji) { try makeInput(emoji: value) }
    }

    @Test(arguments: ["🌱", "🛠️", "🇰🇷", "👍🏽", "👨‍👩‍👧‍👦", "👩🏽‍💻", "1️⃣"])
    func acceptsRepresentativeUnicodeEmojiSequences(_ emoji: String) throws {
        let input = try makeInput(emoji: emoji)

        #expect(input.emoji == emoji)
    }

    @Test("rejects an incorrect interest count")
    func rejectsWrongInterestCount() {
        for invalidInterests in [[], ["연구"], ["연구", "글쓰기"], ["연구", "글쓰기", "디자인", "투자"]] {
            #expect(throws: ProfileInputError.interestCount(expected: 3)) {
                try makeInput(interests: invalidInterests)
            }
        }
    }

    @Test("rejects duplicate interests after trimming")
    func rejectsDuplicateInterestsAfterTrimming() {
        #expect(throws: ProfileInputError.duplicateInterest) {
            try makeInput(interests: ["연구", " 연구 ", "디자인"])
        }
    }

    @Test("rejects an interest that is empty after trimming")
    func rejectsEmptyInterestAfterTrimming() {
        #expect(throws: ProfileInputError.emptyInterest) {
            try makeInput(interests: ["연구", " \n ", "디자인"])
        }
    }

    @Test("rejects an unsupported interest after trimming")
    func rejectsUnsupportedInterestAfterTrimming() {
        #expect(throws: ProfileInputError.unsupportedInterest("해외 축구")) {
            try makeInput(interests: ["연구", "글쓰기", " 해외 축구 "])
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
        let profile = UserProfile(id: "profile-1", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["alpha", "beta", "gamma"], mbti: nil, createdAt: createdAt)
        let card = CardSnapshot(ownerID: "profile-1", seed: "seed", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["alpha", "beta", "gamma"], mbti: nil, version: 1, createdAt: createdAt)

        #expect(profile.currentStatus == "Building an iOS app")
        #expect(profile.lastUpdatedAt == createdAt)
        #expect(card.currentStatus == "Building an iOS app")
    }

    @Test("decodes a legacy profile without an updated-at value")
    func decodesLegacyProfileWithCreatedAtFallback() throws {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let legacyProfile = LegacyUserProfile(id: "profile-1", nickname: "Ana", tagline: "Building an iOS app", emoji: "🌱", interests: ["alpha", "beta", "gamma"], mbti: nil, createdAt: createdAt)

        let data = try JSONEncoder().encode(legacyProfile)
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(profile.updatedAt == nil)
        #expect(profile.lastUpdatedAt == createdAt)
    }

    private func makeInput(nickname: String = "Ana", currentStatus: String = "Building an iOS app", emoji: String = "🌱", interests: [String] = ["연구", "글쓰기", "디자인"]) throws -> ProfileInput {
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
