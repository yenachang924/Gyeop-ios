import Core
import Foundation
import Testing
@testable import DataKit

@Suite("SwiftDataGyeopRepository (in-memory)")
struct SwiftDataGyeopRepositoryTests {
    @Test("프로필·카드 저장/로드 왕복")
    func profileRoundtrip() async throws {
        let repo = try SwiftDataGyeopRepository.inMemory()
        try await repo.saveMyProfile(MockData.sampleProfiles[0])
        try await repo.saveMyCard(MockData.sampleCards[0])
        #expect(try await repo.myProfile() == MockData.sampleProfiles[0])
        #expect(try await repo.myCard() == MockData.sampleCards[0])
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
}
