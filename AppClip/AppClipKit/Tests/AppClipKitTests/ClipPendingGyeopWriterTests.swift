import Core
import Foundation
import Testing
@testable import AppClipKit

@Suite("ClipPendingGyeopWriter")
struct ClipPendingGyeopWriterTests {
    // 테스트 프로세스에도 실제로 존재하는 App Group suite가 없으므로, Apple 예약 접두사 없이
    // 표준 UserDefaults suite로 왕복만 검증한다 — 키·인코딩 형식이 DataKit의
    // ClipMigrationReceiver와 맞는지가 이 테스트의 핵심이다.
    private let suiteName = "AppClipKitTests.pendingGyeops"

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("겹 기록을 App Group UserDefaults에 누적한다")
    func appendsAndAccumulates() throws {
        _ = makeDefaults()
        let writer = ClipPendingGyeopWriter(appGroupID: suiteName)

        writer.append(MockData.sampleGyeops[0])
        writer.append(MockData.sampleGyeops[1])

        let defaults = UserDefaults(suiteName: suiteName)!
        let data = try #require(defaults.data(forKey: ClipPendingGyeopWriter.pendingGyeopsKey))
        let decoded = try JSONDecoder().decode([GyeopRecord].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded.map(\.id) == [MockData.sampleGyeops[0].id, MockData.sampleGyeops[1].id])
    }
}
