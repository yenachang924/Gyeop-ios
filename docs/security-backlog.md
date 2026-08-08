# 보안 백로그 — 코드 수정 없이 기록만 (존 피드백 이후 처리)

가드레일: 이번 정렬 스프린트에서는 보안 구조 변경 금지. 발견 즉시 여기에 기록하고 넘어간다.
존 2차 피드백(질문 목록: `docs/feedback-log.md`) 후 일괄 라우팅.

| # | 발견일 | 이슈 | 위치 | 메모 |
|---|---|---|---|---|
| 1 | 2026-08-08 | 클립→풀앱 마이그레이션 우편함이 App Group **UserDefaults 평문 JSON** — 겹 기록(상대 닉네임·관심사·시각) 저장. 동일 App Group을 가진 확장 간 접근 경계와 at-rest 보호 수준 검토 필요 | `AppClipKit/Migration/ClipPendingGyeopWriter.swift`, `DataKit/ClipMigrationReceiver.swift` | 존 질문 6(30일 정책·고지)과 연결 |
| 2 | 2026-08-08 | App Group 공유 키 `com.gyeop.clip.pendingGyeops`가 두 모듈에 **중복 하드코딩** — 한쪽만 바뀌면 마이그레이션이 조용히 유실됨 (무결성 이슈) | 위와 동일 2파일 | Core 상수화는 코드 변경이라 보류 |
| 3 | 2026-08-08 | 클립 무계정 데이터의 기기 밖 반출 경계가 코드 레벨로 강제되지 않음 (현재는 관례적으로 로컬 온리) | `AppClipKit/Flow/ClipModel.swift` | 존 질문 2와 연결 |
| 4 | 2026-08-08 | MPC 세션 암호화 수준이 `ExchangeConstants`에 명시적 계약으로 고정돼 있지 않음 — `.required` 계획(feedback-log 존 질문 1) 대비 현행 값 확인 필요 | `GyeopKit/MultipeerExchangeSession.swift` | 확인만, 변경 금지 |
