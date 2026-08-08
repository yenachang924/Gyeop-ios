import Core
import Foundation

/// 클립→풀앱 마이그레이션의 쓰기측. 클립과 풀 앱은 같은 프로세스가 아니라 서로 다른 실행
/// 바이너리이므로(설치 시점엔 풀 앱이 아직 없을 수도 있다), `GyeopRepository` 인스턴스를
/// 직접 주고받을 수 없다 — App Group 공유 컨테이너를 우편함처럼 쓴다.
///
/// 읽기측은 DataKit의 `ClipMigrationReceiver`(`Packages/GyeopPackages/Sources/DataKit/ClipMigrationReceiver.swift`)
/// 다. 같은 App Group suite + 같은 키(`pendingGyeopsKey`)를 공유해야 마이그레이션이 성립한다.
///
/// ⚠️ 이 키 문자열은 지금 AppClip·DataKit 두 세션에 각자 하드코딩돼 있다. 원래는 Core로 옮겨
/// 공유 상수화하는 게 맞지만, Core 계약 변경은 관련 세션 합의가 필요해서(CLAUDE.md 소유권 규칙)
/// 이번 세션에서 임의로 건드리지 않았다 — 두 문자열이 반드시 일치해야 한다는 걸
/// AppClip/README.md에도 남겨뒀다.
public struct ClipPendingGyeopWriter: Sendable {
    static let pendingGyeopsKey = "com.gyeop.clip.pendingGyeops"

    private let appGroupID: String

    public init(appGroupID: String) {
        self.appGroupID = appGroupID
    }

    /// 겹 성립 직후(`ClipModel`의 `.completed` 이벤트) 호출한다. App Group 컨테이너가 없거나
    /// (엔타이틀먼트 미설정) 인코딩에 실패해도 클립 플로우 자체는 막지 않는다 —
    /// 마이그레이션은 부가 기능이지 교환 완료의 전제조건이 아니다.
    public func append(_ record: GyeopRecord) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            ClipLog.migration.error("App Group UserDefaults 접근 실패: \(appGroupID, privacy: .public)")
            return
        }

        var pending: [GyeopRecord] = []
        if let data = defaults.data(forKey: Self.pendingGyeopsKey),
           let decoded = try? JSONDecoder().decode([GyeopRecord].self, from: data) {
            pending = decoded
        }
        pending.append(record)

        guard let encoded = try? JSONEncoder().encode(pending) else {
            ClipLog.migration.error("겹 기록 인코딩 실패: \(record.id, privacy: .public)")
            return
        }
        defaults.set(encoded, forKey: Self.pendingGyeopsKey)
    }
}
