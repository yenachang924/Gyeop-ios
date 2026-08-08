# 실기기 필요 항목

시뮬레이터에서 확인 불가한 항목의 목록. 코드에 섞지 말고 여기에 등록한다 (CLAUDE.md 사이클 규칙).
각 항목은 시뮬레이터에서 Mock 경로(Core/Mocks)로 대체 동작해야 한다.

| 항목 | 모듈 | 대체 Mock | 상태 |
|---|---|---|---|
| MultipeerConnectivity 발견·연결·전송 | GyeopKit | `MockExchangeSession` | 미착수 (S2) |
| NearbyInteraction UWB 30cm 트리거 | GyeopKit | `MockExchangeSession` | 미착수 (v0.2) |
| CoreHaptics 교환 햅틱 | GyeopKit | 없음 (실기기에서만 체감) | 미착수 (S2) |
| APNs 푸시 수신 | (SignalKit 예정) | — | 미착수 |
| Live Activity 원격 갱신 | (SignalKit 예정) | — | 미착수 (v0.2) |
| 카드 셰이더 60fps 검증 | CardKit | 시뮬레이터 근사 확인만 | 미착수 (S1 오후) |
