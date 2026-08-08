import AppClipKit
import CardKit
import Core
import DataKit
import Foundation
import GyeopKit

/// 클립 조립 지점 — 여기서만 실구현을 Core 계약에 꽂는다 (본앱 `AppModel.live()`와 대응).
/// 카드 엔진: CardKit 실구현. 저장: App Group 공유 컨테이너 SwiftData(+30일 보존 집행).
/// 교환: 실기기 MPC / 시뮬레이터 Mock (docs/device-required.md). 마이그레이션: 겹 성립 시
/// App Group 우편함(`ClipPendingGyeopWriter`) 적재 — 본앱 부트스트랩이 병합한다.
extension ClipModel {
    static let appGroupID = "group.com.gyeop.app"

    @MainActor
    static func live() -> ClipModel {
        // 시뮬레이터 QA·UI 테스트용: 목업 교환을 실패 시나리오로 강제 (본앱과 같은 스위치)
        let mockFailure: ExchangeFailure? =
            CommandLine.arguments.contains("-mock-exchange-fail") ? .timedOut : nil

        // UI 테스트는 매번 첫 실행이어야 한다 — 인메모리 저장소로 격리
        if CommandLine.arguments.contains("-uitest-reset") {
            return ClipModel(
                cardGenerator: CardGenerator(),
                repository: MockGyeopRepository(),
                makeExchangeSession: { _ in MockExchangeSession(failure: mockFailure) }
            )
        }

        let repository: any GyeopRepository
        do {
            let store = try SwiftDataGyeopRepository.appGroup(id: appGroupID)
            // 30일 보존 집행 — 실행할 때마다 기준선 이전 겹 기록을 지운다
            Task {
                do {
                    try await store.pruneGyeops(before: ClipRetentionPolicy.cutoffDate())
                } catch {
                    ClipLog.migration.error("30일 보존 집행 실패: \(error, privacy: .public)")
                }
            }
            repository = store
        } catch {
            // App Group 미설정·컨테이너 생성 실패 — 클립은 죽지 않고 인메모리로 강등
            ClipLog.flow.error("App Group SwiftData 컨테이너 생성 실패, 인메모리 강등: \(error, privacy: .public)")
            repository = MockGyeopRepository()
        }

        let pendingWriter = ClipPendingGyeopWriter(appGroupID: appGroupID)
        return ClipModel(
            cardGenerator: CardGenerator(),
            repository: repository,
            makeExchangeSession: { card in
                #if targetEnvironment(simulator)
                // MPC는 실기기 전용 (docs/device-required.md) — 시뮬레이터는 스크립트 Mock
                _ = card
                return MockExchangeSession(failure: mockFailure)
                #else
                return MultipeerExchangeSession(displayName: exchangeDisplayName(for: card))
                #endif
            },
            onGyeopRecorded: { pendingWriter.append($0) }
        )
    }

    /// MCPeerID 제약(UTF-8 63바이트)에 맞춘 표시 이름 — 본앱 `AppModel`과 같은 규칙이어야
    /// 클립↔본앱 간 맞대기에서도 피어가 구분된다.
    private nonisolated static func exchangeDisplayName(for card: CardSnapshot) -> String {
        let suffix = String(card.ownerID.suffix(8))
        return "\(String(card.nickname.prefix(12)))#\(suffix)"
    }
}
