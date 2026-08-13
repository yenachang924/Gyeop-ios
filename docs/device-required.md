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
| App Group 실제 공유 컨테이너(AppClip→App 데이터 마이그레이션) | DataKit | `ClipMigrationReceiver`는 UserDefaults(suiteName:) 단위 테스트로 로직만 검증됨 | AppClip 타깃 활성화 완료(통합 세션) — 실기기 교차 프로세스 검증 필요 |
| App Clip 실제 도메인 인보케이션(Associated Domain 검증) | AppClip | 시뮬레이터는 `_XCAppClipURL` 실행 인자로 커스텀 스킴(`gyeop://`) URL 직접 주입 | 미착수 (도메인 소유자 결정 대기) |

## 통합 실행 계획 (제출 전 실기기 세션 1회, 기기 2대 · 약 2시간)

준비물: iPhone 2대(iOS 18+), 개발자 계정 서명, 두 기기 모두 같은 Wi-Fi 또는 Wi-Fi/블루투스 켜기.
v0.2 항목(UWB·Live Activity)과 SignalKit 예정 항목(APNs)은 이번 제출 범위에서 제외.

| 순서 | 항목 | 절차 | 합격 기준 | 상태 |
|---|---|---|---|---|
| 1 | Sign in with Apple | 기기 A·B 각각 첫 실행 → Apple ID 로그인 | 시트 표시·완료 후 온보딩 진입, 재실행 시 게이트 생략 | ✅ 2026-08-09 합격 (소유자 보고 — entitlements 재배선 후) |
| 2 | 온보딩·카드 생성 | 두 기기에서 서로 다른 프로필로 완주 | 카드 리빌까지 크래시 없음 | ✅ 2026-08-09 합격 |
| 3 | 카드 셰이더 60fps | 기기 A에서 카드 상세 열고 Instruments(Core Animation FPS) 또는 Xcode FPS 게이지 | 55fps 이상 유지 | ✅ 2026-08-09 합격 |
| 4 | **MPC 왕복** (핵심) | 양쪽 컬렉션 → 맞대기 → 기기 맞댐. 첫 실행 시 로컬 네트워크 권한 허용 | 3초 이내 겹 성립, 양쪽 컬렉션에 상대 카드, 겹 카운트 일치 | ✅ 2026-08-09 합격 (3초 이내, 양쪽 수신 확인) |
| 5 | MPC 엣지 | ① 한쪽만 맞대기 진입(상대 없음) → 20초 타임아웃 ② 연결 중 한쪽 강제 종료 → peerLost ③ 재시도 성공 ④ 로컬 네트워크 권한 거부 후 맞대기 → 타임아웃 실패 문구에 권한 안내 확인 | 실패 화면(중립 톤) → "다시 맞대기"로 복구 | ✅ 2026-08-09 합격 (4종 전부 정상, 소유자 확인) |
| 6 | 햅틱 체감 | 4번 반복하며 peerFound·connected·completed·failed 패턴 확인 | 각 단계 구분 가능, 과하지 않음 (튜닝 메모 남기기) | ✅ 2026-08-09 합격 (1차 튜닝값 확정 — design-decisions §햅틱 튜닝 기록) |
| 7 | 24h 중복 규칙 | 같은 상대와 연속 2회 맞대기 | 겹 카운트 1회만 증가 | ✅ 2026-08-09 합격 |
| 8 | App Group 마이그레이션 | (도메인 확정 전 로컬 검증) 기기 A에 GyeopClip 타깃 직접 설치 → `_XCAppClipURL` 스킴 인자로 클립 플로우 → 겹 성립 → 본앱 실행 | 본앱 부트스트랩에서 클립 겹 병합됨 (컬렉션에 표시) | ✅ 2026-08-09 합격 (로컬 검증 — 실도메인 인보케이션은 별건) |
| 9 | 계정 삭제 | 기기 B 설정 > 계정 삭제 → 재실행 | 로그인 게이트부터 다시, 데이터 0건 | ✅ 2026-08-09 합격 |
| 10 | 시연 영상 촬영 | `docs/review-kit.md` §2 촬영 목록 그대로 | 5컷 확보 | – |
| 11 | MPC 4대 동시 | 4대가 같은 공간에서 동시에 맞대기 진입 (2026-08-13 "2대 보류" 재현 조건). 초대 조건부 수락·락 해제 수정(2af6475) 검증 | 잘못 짝지어진 기기도 타임아웃 내 재시도로 복구, 보류 고착 없음. 의도한 짝 보장은 UWB(v0.2) 전까지 미보장임을 유의 | – |

⚠️ 8번의 실도메인 AASA 인보케이션(태그/QR → 클립 자동 실행)은 도메인 확정 후에만 가능 — 제출 리스크 목록에 유지.
