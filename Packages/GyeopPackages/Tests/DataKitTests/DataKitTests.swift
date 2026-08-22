import Core
import Foundation
import Testing
@testable import DataKit

@Suite("SwiftDataGyeopRepository (in-memory)")
struct SwiftDataGyeopRepositoryTests {
    @Test("profile and card replacements persist through one atomic repository operation")
    func atomicProfileAndCardSave() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        let profile = MockData.sampleProfiles[2]
        let card = MockData.sampleCards[2]

        try await repo.saveProfileAndCard(profile: profile, card: card)

        #expect(try await repo.myProfile() == profile)
        #expect(try await repo.myCard() == card)
    }

    @Test("프로필·카드 저장/로드 왕복")
    func profileRoundtrip() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        #expect(try await repo.myProfile() == MockData.sampleProfiles[0])
        #expect(try await repo.myCard() == MockData.sampleCards[0])
    }

    @Test("profile updatedAt survives persistence independently from createdAt")
    func profileUpdatedAtRoundtrip() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let updatedAt = Date(timeIntervalSince1970: 2_000)
        let profile = UserProfile(
            id: "profile-updated-at",
            nickname: "Yena",
            tagline: "Building an iOS app",
            emoji: "🌱",
            interests: ["연구", "글쓰기", "디자인"],
            mbti: MBTI(code: "ENFP"),
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        try await repo.saveMyProfile(profile)

        let restored = try await repo.myProfile()
        #expect(restored?.createdAt == createdAt)
        #expect(restored?.updatedAt == updatedAt)
    }

    @Test("프로필 재저장은 덮어쓴다 (1건 유지)")
    func profileUpsert() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyProfile(MockData.sampleProfiles[1])
        #expect(try await repo.myProfile() == MockData.sampleProfiles[1])
    }

    @Test("같은 GyeopID 중복 기록은 1건 (멱등)")
    func idempotentRecord() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.record(MockData.sampleGyeops[0])
        try await repo.record(MockData.sampleGyeops[0])
        #expect(try await repo.gyeops().count == 1)
    }

    @Test("gyeops는 최신순으로 온다")
    func sortedByOccurredAt() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        for gyeop in MockData.sampleGyeops {
            try await repo.record(gyeop)
        }
        let fetched = try await repo.gyeops()
        #expect(fetched.count == MockData.sampleGyeops.count)
        #expect(fetched == fetched.sorted { $0.occurredAt > $1.occurredAt })
    }

    @Test("collectedCards는 러너당 최신 카드 1장, 최신순")
    func collectedCardsDedupesByOwner() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        for gyeop in MockData.sampleGyeops {
            try await repo.record(gyeop)
        }
        let expectedOwners = MockData.sampleGyeops
            .sorted { $0.occurredAt > $1.occurredAt }
            .map { $0.counterpartCard.ownerID }

        let cards = try await repo.collectedCards()

        #expect(cards.map(\.ownerID) == expectedOwners)
    }

    @Test("동일 상대와 24시간 이내 재맞댐은 1건으로 집계 (어뷰징 방지)")
    func recentSameCounterpartCollapsesToOneRecord() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        let card = MockData.sampleCards[0]
        let first = GyeopRecord(
            id: GyeopID.make(participantA: "user-me", participantB: card.ownerID, serverCorrectedDate: MockData.referenceDate),
            counterpartCard: card,
            method: .mock,
            occurredAt: MockData.referenceDate
        )
        let secondSameDay = GyeopRecord(
            id: GyeopID.make(
                participantA: "user-me", participantB: card.ownerID,
                serverCorrectedDate: MockData.referenceDate.addingTimeInterval(3600)
            ),
            counterpartCard: card,
            method: .mock,
            occurredAt: MockData.referenceDate.addingTimeInterval(3600)
        )

        try await repo.record(first)
        try await repo.record(secondSameDay)

        #expect(try await repo.gyeops().count == 1)
    }

    @Test("동일 상대라도 24시간이 지나면 새 겹으로 집계")
    func sameCounterpartAfter24HoursCountsAgain() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        let card = MockData.sampleCards[0]
        let first = GyeopRecord(
            id: GyeopID.make(participantA: "user-me", participantB: card.ownerID, serverCorrectedDate: MockData.referenceDate),
            counterpartCard: card,
            method: .mock,
            occurredAt: MockData.referenceDate
        )
        let nextDay = GyeopRecord(
            id: GyeopID.make(
                participantA: "user-me", participantB: card.ownerID,
                serverCorrectedDate: MockData.referenceDate.addingTimeInterval(25 * 3600)
            ),
            counterpartCard: card,
            method: .mock,
            occurredAt: MockData.referenceDate.addingTimeInterval(25 * 3600)
        )

        try await repo.record(first)
        try await repo.record(nextDay)

        #expect(try await repo.gyeops().count == 2)
    }

    @Test("다른 상대는 24시간 이내라도 각각 집계된다")
    func differentCounterpartsWithin24HoursBothCount() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        let cardA = MockData.sampleCards[0]
        let cardB = MockData.sampleCards[1]
        let recordA = GyeopRecord(
            id: GyeopID.make(participantA: "user-me", participantB: cardA.ownerID, serverCorrectedDate: MockData.referenceDate),
            counterpartCard: cardA,
            method: .mock,
            occurredAt: MockData.referenceDate
        )
        let recordB = GyeopRecord(
            id: GyeopID.make(participantA: "user-me", participantB: cardB.ownerID, serverCorrectedDate: MockData.referenceDate),
            counterpartCard: cardB,
            method: .mock,
            occurredAt: MockData.referenceDate
        )

        try await repo.record(recordA)
        try await repo.record(recordB)

        #expect(try await repo.gyeops().count == 2)
    }

    @Test("계정 삭제 후 프로필·카드·겹 기록 0건")
    func deleteAllLocalDataWipesEverything() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        for gyeop in MockData.sampleGyeops {
            try await repo.record(gyeop)
        }

        try await repo.deleteAllLocalData()

        #expect(try await repo.myProfile() == nil)
        #expect(try await repo.myCard() == nil)
        #expect(try await repo.gyeops().isEmpty)
    }

    @Test("pruneGyeops는 기준선 이전 기록만 지운다 (클립 30일 보존 집행)")
    func pruneDeletesOnlyRecordsBeforeCutoff() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        // sampleGyeops는 참조일 + 0·1·2일 간격 — 서로 다른 상대라 24h 규칙에 안 걸린다
        for gyeop in MockData.sampleGyeops {
            try await repo.record(gyeop)
        }
        let cutoff = MockData.referenceDate.addingTimeInterval(1.5 * 86_400)

        try await repo.pruneGyeops(before: cutoff)

        let remaining = try await repo.gyeops()
        #expect(remaining.count == 1)
        #expect(remaining.allSatisfy { $0.occurredAt >= cutoff })
    }
}
