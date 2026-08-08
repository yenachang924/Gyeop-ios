import Core
import Foundation

/// App Clip → 본앱 전환 시 App Group 공유 컨테이너에 남은 데이터를 읽어 본앱
/// 저장소로 병합하는 수신측. AppClip 타깃은 아직 project.yml에 비활성 상태다
/// (`AppClip/README.md` 참조, S6이 활성화) — 이 타입은 그 전제 없이도 독립적으로
/// 컴파일·테스트 가능하도록 App Group ID를 주입받는다.
public struct ClipMigrationReceiver: Sendable {
    static let pendingGyeopsKey = "com.gyeop.clip.pendingGyeops"

    private let appGroupID: String
    private let repository: any GyeopRepository

    public init(appGroupID: String, repository: any GyeopRepository) {
        self.appGroupID = appGroupID
        self.repository = repository
    }

    /// AppClip이 App Group에 남긴 겹 기록을 읽어 병합하고, 병합에 쓴 원본은 지운다.
    /// 멱등 — 같은 GyeopID/24시간 동일 상대 규칙은 리포지토리 쪽에서 걸러진다.
    /// App Group 컨테이너가 없거나(App Group 미설정) 남은 데이터가 없으면 0을 반환한다.
    @discardableResult
    public func migrate() async throws -> Int {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return 0 }
        guard let data = defaults.data(forKey: Self.pendingGyeopsKey) else { return 0 }

        let pending = try JSONDecoder().decode([GyeopRecord].self, from: data)
        for record in pending {
            try await repository.record(record)
        }
        defaults.removeObject(forKey: Self.pendingGyeopsKey)
        return pending.count
    }
}
