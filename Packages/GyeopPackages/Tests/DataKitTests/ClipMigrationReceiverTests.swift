import Core
import Foundation
import Testing
@testable import DataKit

@Suite("ClipMigrationReceiver")
struct ClipMigrationReceiverTests {
    /// 테스트마다 독립된 UserDefaults suite를 써서 서로 간섭하지 않게 한다.
    private func makeSuite() -> (id: String, defaults: UserDefaults) {
        let id = "group.com.gyeop.app.tests.\(UUID().uuidString)"
        return (id, UserDefaults(suiteName: id)!)
    }

    @Test("App Group에 남은 겹 기록을 리포지토리로 병합하고 원본은 지운다")
    func migratesPendingGyeops() async throws {
        let (groupID, defaults) = makeSuite()
        defer { defaults.removePersistentDomain(forName: groupID) }

        let pending = [MockData.sampleGyeops[0], MockData.sampleGyeops[1]]
        defaults.set(try JSONEncoder().encode(pending), forKey: ClipMigrationReceiver.pendingGyeopsKey)

        let repo = try SwiftDataGyeopRepository.inMemory()
        let migrated = try await ClipMigrationReceiver(appGroupID: groupID, repository: repo).migrate()

        #expect(migrated == 2)
        #expect(try await repo.gyeops().count == 2)
        #expect(defaults.data(forKey: ClipMigrationReceiver.pendingGyeopsKey) == nil)
    }

    @Test("남은 데이터가 없으면 0을 반환하고 아무것도 병합하지 않는다")
    func noPendingDataReturnsZero() async throws {
        let (groupID, defaults) = makeSuite()
        defer { defaults.removePersistentDomain(forName: groupID) }

        let repo = try SwiftDataGyeopRepository.inMemory()
        let migrated = try await ClipMigrationReceiver(appGroupID: groupID, repository: repo).migrate()

        #expect(migrated == 0)
        #expect(try await repo.gyeops().isEmpty)
    }

    @Test("병합은 멱등 — 같은 겹 기록을 두 번 병합해도 1건")
    func migrationIsIdempotent() async throws {
        let (groupID, defaults) = makeSuite()
        defer { defaults.removePersistentDomain(forName: groupID) }

        let pending = [MockData.sampleGyeops[0]]
        let repo = try SwiftDataGyeopRepository.inMemory()

        defaults.set(try JSONEncoder().encode(pending), forKey: ClipMigrationReceiver.pendingGyeopsKey)
        try await ClipMigrationReceiver(appGroupID: groupID, repository: repo).migrate()

        defaults.set(try JSONEncoder().encode(pending), forKey: ClipMigrationReceiver.pendingGyeopsKey)
        try await ClipMigrationReceiver(appGroupID: groupID, repository: repo).migrate()

        #expect(try await repo.gyeops().count == 1)
    }
}
