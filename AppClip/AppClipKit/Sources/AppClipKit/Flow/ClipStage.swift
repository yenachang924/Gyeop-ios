import Core
import Foundation

/// 클립 플로우 단계 — `docs/navigation-map.md` §1 클립 레인과 1:1.
/// clip(수신) → 온보딩 3단계 → card → bump → overlap → keep → done.
/// SKOverlay 설치 제안은 `keep`에서만 가능하다 — 그 이전 단계 화면 어디에도
/// 설치 유도 UI가 없다는 것이 이 제품의 핵심 주장이고, 도달 가능한 상태 자체로 강제된다.
public enum ClipStage: Sendable, Equatable {
    /// 1 `clip` — 카드 수신 (발신자 표시 + 「내 카드 만들기」 + 설명 시트)
    case reception
    /// 2~4 `interests`→`vibe`→`intro` — 본앱 온보딩 3단계 뷰 재사용 (클립 타깃에서 조립)
    case onboarding
    /// 5 `card` — 내 카드 완성, 「맞대기」 진입
    case card(CardSnapshot)
    /// 6 `bump` — 교환 진행 중 (실기기 MPC 자동 트리거 / 시뮬레이터 Mock)
    case bump
    /// 7 `overlap` — 겹 결과 (겹치는 관심사 + 받은 카드), 「카드 받기」
    case overlap(GyeopRecord)
    /// 8 `keep` — 보관·전환 제안. **여기서만** 「전체 앱 받기」→ SKOverlay
    case keep(GyeopRecord)
    /// 9 `done` — 나의 겹 (클립 컬렉션)
    case done(GyeopRecord)
    /// 교환 실패 — 「다시 시도」로 bump 재진입
    case failed(ExchangeFailure)
}
