import Core
import Foundation
import SwiftData

/// SwiftData 기반 `GyeopRepository` 실구현 (로컬 전용 — 서버 동기화는 v0.3).
@ModelActor
public actor SwiftDataGyeopRepository: GyeopRepository {
    public static func live() throws -> SwiftDataGyeopRepository {
        SwiftDataGyeopRepository(
            modelContainer: try ModelContainer(
                for: RunnerProfileEntity.self, MyCardEntity.self, GyeopEntity.self
            )
        )
    }

    public static func inMemory() throws -> SwiftDataGyeopRepository {
        SwiftDataGyeopRepository(
            modelContainer: try ModelContainer(
                for: RunnerProfileEntity.self, MyCardEntity.self, GyeopEntity.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    // MARK: - GyeopRepository

    public func saveMyProfile(_ profile: RunnerProfile) async throws {
        if let existing = try fetchSingleton(RunnerProfileEntity.self) {
            existing.update(with: profile)
        } else {
            modelContext.insert(RunnerProfileEntity(profile: profile))
        }
        try modelContext.save()
    }

    public func myProfile() async throws -> RunnerProfile? {
        try fetchSingleton(RunnerProfileEntity.self)?.toDomain()
    }

    public func saveMyCard(_ card: CardSnapshot) async throws {
        if let existing = try fetchSingleton(MyCardEntity.self) {
            existing.update(with: card)
        } else {
            modelContext.insert(MyCardEntity(card: card))
        }
        try modelContext.save()
    }

    public func myCard() async throws -> CardSnapshot? {
        try fetchSingleton(MyCardEntity.self)?.toDomain()
    }

    /// 멱등 저장. 두 단계로 중복을 걸러낸다:
    /// 1) 결정적 `GyeopID`가 이미 있으면 같은 만남(양쪽 기기가 독립 계산해도 동일 ID) — 그대로 무시.
    /// 2) ID는 다르지만(다른 5분 슬롯) 같은 상대와 24시간 이내 재맞댐이면 어뷰징 방지 규칙으로 무시
    ///    (spec F2 수용 기준: "동일 상대 재맞댐은 24시간 1회만 겹으로 집계").
    public func record(_ gyeop: GyeopRecord) async throws {
        if try existingEntity(id: gyeop.id) != nil {
            await MetricCounter.shared.increment(Metric.exchangeDuplicate)
            return
        }
        if try hasRecentGyeop(withCounterpart: gyeop.counterpartCard.ownerID, near: gyeop.occurredAt) {
            await MetricCounter.shared.increment(Metric.exchangeDuplicate)
            return
        }
        modelContext.insert(GyeopEntity(record: gyeop))
        try modelContext.save()
    }

    public func gyeops() async throws -> [GyeopRecord] {
        let descriptor = FetchDescriptor<GyeopEntity>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    // MARK: - 계정 삭제 (심사 필수)

    /// 로컬에 저장된 프로필·카드·겹 기록을 전부 지운다. Keychain 토큰 삭제는
    /// `AccountDeletionService`가 이 메서드와 함께 묶어서 호출한다.
    public func deleteAllLocalData() async throws {
        try modelContext.delete(model: RunnerProfileEntity.self)
        try modelContext.delete(model: MyCardEntity.self)
        try modelContext.delete(model: GyeopEntity.self)
        try modelContext.save()
    }

    // MARK: - Helpers

    private func fetchSingleton<T: PersistentModel>(_ type: T.Type) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func existingEntity(id: String) throws -> GyeopEntity? {
        var descriptor = FetchDescriptor<GyeopEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func hasRecentGyeop(withCounterpart ownerID: String, near date: Date) throws -> Bool {
        let windowStart = date.addingTimeInterval(-GyeopEntity.dedupWindow)
        let windowEnd = date.addingTimeInterval(GyeopEntity.dedupWindow)
        var descriptor = FetchDescriptor<GyeopEntity>(
            predicate: #Predicate { entity in
                entity.counterpartOwnerID == ownerID &&
                    entity.occurredAt >= windowStart &&
                    entity.occurredAt <= windowEnd
            }
        )
        descriptor.fetchLimit = 1
        return try !modelContext.fetch(descriptor).isEmpty
    }
}
