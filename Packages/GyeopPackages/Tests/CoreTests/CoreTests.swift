import Foundation
import Testing
@testable import Core

@Suite("DeterministicHash and GyeopID")
struct DeterministicHashTests {
    @Test("hashes the known sha256 vector")
    func sha256KnownVector() {
        #expect(DeterministicHash.sha256Hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("uses participant-order-independent identifiers")
    func orderIndependence() {
        let date = Date(timeIntervalSince1970: 1_785_000_000)
        let a = GyeopID.make(participantA: "user-1", participantB: "user-2", serverCorrectedDate: date)
        let b = GyeopID.make(participantA: "user-2", participantB: "user-1", serverCorrectedDate: date)
        #expect(a == b)
    }

    @Test("buckets identifiers by five-minute intervals")
    func timeSlotBucketing() {
        let base = Date(timeIntervalSince1970: 1_785_000_000)
        let sameSlot = GyeopID.make(participantA: "a", participantB: "b", serverCorrectedDate: base.addingTimeInterval(200))
        let nextSlot = GyeopID.make(participantA: "a", participantB: "b", serverCorrectedDate: base.addingTimeInterval(600))
        let reference = GyeopID.make(participantA: "a", participantB: "b", serverCorrectedDate: base)
        #expect(reference == sameSlot)
        #expect(reference != nextSlot)
    }
}

@Suite("MockCardGenerator")
struct MockCardGeneratorTests {
    @Test("creates the same seed for the same profile")
    func deterministicSeed() {
        let profile = MockData.sampleProfiles[0]
        let generator = MockCardGenerator()
        #expect(generator.makeCard(from: profile).seed == generator.makeCard(from: profile).seed)
    }

    @Test("changes the seed when interests change")
    func inputChangesSeed() {
        let profile = MockData.sampleProfiles[0]
        let changed = UserProfile(id: profile.id, nickname: profile.nickname, tagline: profile.tagline, emoji: profile.emoji, interests: profile.interests + ["Food"], mbti: profile.mbti, createdAt: profile.createdAt, updatedAt: profile.updatedAt)
        let generator = MockCardGenerator()
        #expect(generator.makeCard(from: profile).seed != generator.makeCard(from: changed).seed)
    }

    @Test("changes the seed when card version changes")
    func versionChangesSeed() {
        let profile = MockData.sampleProfiles[0]
        let generator = MockCardGenerator()
        #expect(generator.makeCard(from: profile, version: 1).seed != generator.makeCard(from: profile, version: 2).seed)
    }
}

@Suite("MockExchangeSession")
struct MockExchangeSessionTests {
    @Test("emits searching then completion on the happy path")
    func happyPath() async throws {
        let session = MockExchangeSession(stepDelay: .zero)
        try await session.start(broadcasting: MockData.sampleCards[1])
        var events: [ExchangeEvent] = []
        for await event in session.events { events.append(event) }
        #expect(events.first == .searching)
        guard case .completed(let record)? = events.last else {
            Issue.record("Expected a completed event")
            return
        }
        #expect(record.counterpartCard == MockData.sampleCards[0])
        #expect(record.method == .mock)
    }

    @Test("emits failure when configured to fail")
    func failurePath() async throws {
        let session = MockExchangeSession(stepDelay: .zero, failure: .timedOut)
        try await session.start(broadcasting: MockData.sampleCards[1])
        var last: ExchangeEvent?
        for await event in session.events { last = event }
        #expect(last == .failed(.timedOut))
    }
}

@Suite("MockGyeopRepository")
struct MockGyeopRepositoryTests {
    @Test("round-trips the saved profile and card")
    func profileRoundtrip() async throws {
        let repo = MockGyeopRepository()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        #expect(try await repo.myProfile() == MockData.sampleProfiles[0])
        #expect(try await repo.myCard() == MockData.sampleCards[0])
    }

    @Test("stores duplicate records only once")
    func idempotentRecord() async throws {
        let repo = MockGyeopRepository()
        try await repo.record(MockData.sampleGyeops[0])
        try await repo.record(MockData.sampleGyeops[0])
        #expect(try await repo.gyeops().count == 1)
    }

    @Test("sorts records and returns one collected card per record")
    func sortingAndCollection() async throws {
        let repo = MockGyeopRepository(seededGyeops: MockData.sampleGyeops)
        let gyeops = try await repo.gyeops()
        #expect(gyeops == gyeops.sorted { $0.occurredAt > $1.occurredAt })
        #expect(try await repo.collectedCards().count == MockData.sampleGyeops.count)
    }
}

@Suite("MetricCounter")
struct MetricCounterTests {
    @Test("draining resets the counter")
    func drainResets() async {
        let counter = MetricCounter()
        await counter.increment(Metric.exchangeAttempt)
        await counter.increment(Metric.exchangeAttempt)
        let drained = await counter.drain()
        #expect(drained[Metric.exchangeAttempt] == 2)
        #expect(await counter.snapshot().isEmpty)
    }
}
