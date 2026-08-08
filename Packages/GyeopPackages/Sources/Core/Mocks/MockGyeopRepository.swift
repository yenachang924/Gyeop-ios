import Foundation

/// 인메모리 목업 저장소. DataKit의 SwiftData 실구현이 오기 전까지의 접점이자
/// 테스트·프리뷰의 기본 저장소.
public actor MockGyeopRepository: GyeopRepository {
    private var profile: RunnerProfile?
    private var card: CardSnapshot?
    private var records: [String: GyeopRecord] = [:]

    public init(seededGyeops: [GyeopRecord] = []) {
        for record in seededGyeops {
            records[record.id] = record
        }
    }

    public func saveMyProfile(_ profile: RunnerProfile) async throws {
        self.profile = profile
    }

    public func myProfile() async throws -> RunnerProfile? { profile }

    public func saveMyCard(_ card: CardSnapshot) async throws {
        self.card = card
    }

    public func myCard() async throws -> CardSnapshot? { card }

    public func record(_ gyeop: GyeopRecord) async throws {
        if records[gyeop.id] != nil {
            await MetricCounter.shared.increment(Metric.exchangeDuplicate)
            return
        }
        records[gyeop.id] = gyeop
    }

    public func gyeops() async throws -> [GyeopRecord] {
        records.values.sorted { $0.occurredAt > $1.occurredAt }
    }
}
