import Foundation
import Testing
@testable import Core

@Suite("결정적 해시 · GyeopID")
struct DeterministicHashTests {
    @Test("sha256 알려진 벡터")
    func sha256KnownVector() {
        #expect(
            DeterministicHash.sha256Hex("abc")
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test("러너 순서를 바꿔도 같은 GyeopID")
    func orderIndependence() {
        let date = Date(timeIntervalSince1970: 1_785_000_000)
        let a = GyeopID.make(participantA: "user-1", participantB: "user-2", serverCorrectedDate: date)
        let b = GyeopID.make(participantA: "user-2", participantB: "user-1", serverCorrectedDate: date)
        #expect(a == b)
    }

    @Test("같은 5분 슬롯이면 같은 ID, 슬롯이 다르면 다른 ID")
    func timeSlotBucketing() {
        let base = Date(timeIntervalSince1970: 1_785_000_000)
        let sameSlot = GyeopID.make(
            participantA: "a", participantB: "b",
            serverCorrectedDate: base.addingTimeInterval(200)
        )
        let nextSlot = GyeopID.make(
            participantA: "a", participantB: "b",
            serverCorrectedDate: base.addingTimeInterval(600)
        )
        let reference = GyeopID.make(participantA: "a", participantB: "b", serverCorrectedDate: base)
        #expect(reference == sameSlot)
        #expect(reference != nextSlot)
    }
}

@Suite("MockCardGenerator")
struct MockCardGeneratorTests {
    @Test("같은 프로필 = 같은 시드 (결정성)")
    func deterministicSeed() {
        let profile = MockData.sampleProfiles[0]
        let generator = MockCardGenerator()
        #expect(generator.makeCard(from: profile).seed == generator.makeCard(from: profile).seed)
    }

    @Test("입력이 다르면 시드도 다르다")
    func inputChangesSeed() {
        let profile = MockData.sampleProfiles[0]
        let changed = UserProfile(
            id: profile.id,
            nickname: profile.nickname,
            tagline: profile.tagline,
            emoji: profile.emoji,
            interests: profile.interests + ["러닝"],
            mbti: profile.mbti,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
        let generator = MockCardGenerator()
        #expect(
            generator.makeCard(from: profile).seed
                != generator.makeCard(from: changed).seed
        )
    }

    @Test("버전이 오르면 카드가 자란다 (다른 시드)")
    func versionChangesSeed() {
        let profile = MockData.sampleProfiles[0]
        let generator = MockCardGenerator()
        #expect(
            generator.makeCard(from: profile, version: 1).seed
                != generator.makeCard(from: profile, version: 2).seed
        )
    }
}

@Suite("MockExchangeSession")
struct MockExchangeSessionTests {
    @Test("기본 스크립트는 searching→…→completed로 끝난다")
    func happyPath() async throws {
        let session = MockExchangeSession(stepDelay: .zero)
        try await session.start(broadcasting: MockData.sampleCards[1])

        var events: [ExchangeEvent] = []
        for await event in session.events {
            events.append(event)
        }

        #expect(events.first == .searching)
        guard case .completed(let record)? = events.last else {
            Issue.record("마지막 이벤트가 completed가 아님: \(String(describing: events.last))")
            return
        }
        #expect(record.counterpartCard == MockData.sampleCards[0])
        #expect(record.method == .mock)
    }

    @Test("failure 지정 시 failed로 끝난다")
    func failurePath() async throws {
        let session = MockExchangeSession(stepDelay: .zero, failure: .timedOut)
        try await session.start(broadcasting: MockData.sampleCards[1])

        var last: ExchangeEvent?
        for await event in session.events {
            last = event
        }
        #expect(last == .failed(.timedOut))
    }
}

@Suite("MockGyeopRepository")
struct MockGyeopRepositoryTests {
    @Test("atomic profile and card failure leaves both stored values unchanged")
    func atomicProfileAndCardFailureRollsBack() async throws {
        let initialProfile = MockData.sampleProfiles[0]
        let initialCard = MockData.sampleCards[0]
        let replacementProfile = MockData.sampleProfiles[1]
        let replacementCard = MockData.sampleCards[1]
        let repo = MockGyeopRepository(
            initialProfile: initialProfile,
            initialCard: initialCard,
            failProfileAndCardSave: true
        )

        do {
            try await repo.saveProfileAndCard(
                profile: replacementProfile,
                card: replacementCard
            )
            Issue.record("fault-injected atomic save should throw")
        } catch {
            #expect(error as? MockGyeopRepositoryError == .profileAndCardSaveFailed)
        }

        #expect(try await repo.myProfile() == initialProfile)
        #expect(try await repo.myCard() == initialCard)
    }

    @Test("atomic profile and card success publishes both replacement values")
    func atomicProfileAndCardSuccess() async throws {
        let repo = MockGyeopRepository()
        let profile = MockData.sampleProfiles[1]
        let card = MockData.sampleCards[1]

        try await repo.saveProfileAndCard(profile: profile, card: card)

        #expect(try await repo.myProfile() == profile)
        #expect(try await repo.myCard() == card)
    }

    @Test("프로필·카드 저장/로드 왕복")
    func profileRoundtrip() async throws {
        let repo = MockGyeopRepository()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        #expect(try await repo.myProfile() == MockData.sampleProfiles[0])
        #expect(try await repo.myCard() == MockData.sampleCards[0])
    }

    @Test("같은 GyeopID 중복 기록은 1건 (멱등)")
    func idempotentRecord() async throws {
        let repo = MockGyeopRepository()
        try await repo.record(MockData.sampleGyeops[0])
        try await repo.record(MockData.sampleGyeops[0])
        #expect(try await repo.gyeops().count == 1)
    }

    @Test("gyeops는 최신순, collectedCards는 러너당 1장")
    func sortingAndCollection() async throws {
        let repo = MockGyeopRepository(seededGyeops: MockData.sampleGyeops)
        let gyeops = try await repo.gyeops()
        #expect(gyeops == gyeops.sorted { $0.occurredAt > $1.occurredAt })
        #expect(try await repo.collectedCards().count == MockData.sampleGyeops.count)
    }
}

@Suite("MetricCounter")
struct MetricCounterTests {
    @Test("increment 후 drain하면 비워진다")
    func drainResets() async {
        let counter = MetricCounter()
        await counter.increment(Metric.exchangeAttempt)
        await counter.increment(Metric.exchangeAttempt)
        let drained = await counter.drain()
        #expect(drained[Metric.exchangeAttempt] == 2)
        #expect(await counter.snapshot().isEmpty)
    }
}
