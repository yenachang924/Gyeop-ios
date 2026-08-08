import Core
import Foundation
import SwiftData

/// SwiftData 저장 레코드. 스키마 확정 전이라 페이로드는 JSON 블롭으로 둔다 —
/// 도메인 모델(Core)이 스키마에 묶이지 않게 하는 임시 경계. DataKit 세션이
/// 정식 스키마(+동기화 큐)로 교체하되 `GyeopRepository` 계약은 유지한다.
@Model
final class StoredRecord {
    @Attribute(.unique) var key: String
    var kind: String
    var payload: Data
    var sortDate: Date

    init(key: String, kind: String, payload: Data, sortDate: Date) {
        self.key = key
        self.kind = kind
        self.payload = payload
        self.sortDate = sortDate
    }
}

/// SwiftData 기반 `GyeopRepository` 실구현 (로컬 전용 — 서버 동기화는 v0.3).
@ModelActor
public actor SwiftDataGyeopRepository: GyeopRepository {
    private enum Kind {
        static let profile = "profile"
        static let card = "card"
        static let gyeop = "gyeop"
    }

    public static func live() throws -> SwiftDataGyeopRepository {
        SwiftDataGyeopRepository(
            modelContainer: try ModelContainer(for: StoredRecord.self)
        )
    }

    public static func inMemory() throws -> SwiftDataGyeopRepository {
        SwiftDataGyeopRepository(
            modelContainer: try ModelContainer(
                for: StoredRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    // MARK: - GyeopRepository

    public func saveMyProfile(_ profile: RunnerProfile) async throws {
        try upsert(key: Kind.profile, kind: Kind.profile, value: profile, sortDate: profile.createdAt)
    }

    public func myProfile() async throws -> RunnerProfile? {
        try fetchOne(key: Kind.profile)
    }

    public func saveMyCard(_ card: CardSnapshot) async throws {
        try upsert(key: Kind.card, kind: Kind.card, value: card, sortDate: card.createdAt)
    }

    public func myCard() async throws -> CardSnapshot? {
        try fetchOne(key: Kind.card)
    }

    public func record(_ gyeop: GyeopRecord) async throws {
        let key = "gyeop.\(gyeop.id)"
        if try existing(key: key) != nil {
            // 결정적 GyeopID 멱등성: 같은 만남은 1건
            await MetricCounter.shared.increment(Metric.exchangeDuplicate)
            return
        }
        try upsert(key: key, kind: Kind.gyeop, value: gyeop, sortDate: gyeop.occurredAt)
    }

    public func gyeops() async throws -> [GyeopRecord] {
        let kind = Kind.gyeop
        let descriptor = FetchDescriptor<StoredRecord>(
            predicate: #Predicate { $0.kind == kind },
            sortBy: [SortDescriptor(\.sortDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map {
            try JSONDecoder().decode(GyeopRecord.self, from: $0.payload)
        }
    }

    // MARK: - Helpers

    private func existing(key: String) throws -> StoredRecord? {
        var descriptor = FetchDescriptor<StoredRecord>(
            predicate: #Predicate { $0.key == key }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsert(key: String, kind: String, value: some Encodable, sortDate: Date) throws {
        let payload = try JSONEncoder().encode(value)
        if let found = try existing(key: key) {
            found.payload = payload
            found.sortDate = sortDate
        } else {
            modelContext.insert(
                StoredRecord(key: key, kind: kind, payload: payload, sortDate: sortDate)
            )
        }
        try modelContext.save()
    }

    private func fetchOne<T: Decodable>(key: String) throws -> T? {
        guard let found = try existing(key: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: found.payload)
    }
}
