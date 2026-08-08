# 실기기 필요 항목

시뮬레이터에서 확인 불가한 항목의 목록. 코드에 섞지 말고 여기에 등록한다 (CLAUDE.md 사이클 규칙).
각 항목은 시뮬레이터에서 Mock 경로(Core/Mocks)로 대체 동작해야 한다.

| 항목 | 모듈 | 대체 Mock | 상태 |
|---|---|---|---|
| MultipeerConnectivity 발견·연결·전송 | GyeopKit | `MockExchangeSession` | 상태 머신 구현 완료(`MultipeerExchangeSession`) — 실기기 2대 왕복 확인 필요 (S2) |
| NearbyInteraction UWB 30cm 트리거 | GyeopKit | `MockExchangeSession` | 미착수 (v0.2) |
| CoreHaptics 교환 햅틱 | GyeopKit | 없음 (실기기에서만 체감, `HapticFeedback`은 시뮬레이터에서 안전하게 no-op) | 기본 패턴 자리 구현 완료 — 감각 튜닝은 D1 결정 대기, 실기기 체감 확인 필요 (S2) |
| APNs 푸시 수신 | (SignalKit 예정) | — | 미착수 |
| Live Activity 원격 갱신 | (SignalKit 예정) | — | 미착수 (v0.2) |
| 카드 셰이더 60fps 검증 | CardKit | 시뮬레이터 근사 확인만 | 미착수 (S1 오후) |
| Sign in with Apple 실사용자 플로우(ASAuthorizationController 표시·응답) | DataKit | 없음(시뮬레이터에서 Apple ID로 직접 확인) | 구현 완료, 시뮬레이터 수동 확인 대기 |
| App Group 실제 공유 컨테이너(AppClip→App 데이터 마이그레이션) | DataKit | `ClipMigrationReceiver`는 UserDefaults(suiteName:) 단위 테스트로 로직만 검증됨 | AppClip 타깃 비활성(S6 활성화 전) — 활성화 후 실기기 교차 프로세스 검증 필요 |
| App Clip 실제 도메인 인보케이션(Associated Domain 검증) | AppClip | 시뮬레이터는 `_XCAppClipURL` 실행 인자로 커스텀 스킴(`gyeop://`) URL 직접 주입 | 미착수 (도메인 소유자 결정 대기) |
