# 제출 체크리스트 (App Store Connect)

상태: ✅ 완료 · 🔧 이 레포에서 준비됨(외부 작업 남음) · ⏳ 외부 의존 대기 · 미착수

**최종 갱신 2026-08-22 (Build 5).** 이 문서는 App Clip 시절 기준으로 오래 방치돼 있었다 —
아래는 코드를 직접 확인해 맞춘 값이다.

## A. 코드·빌드 (레포에서 완결)

- [x] ✅ 패키지 구성: Core · DesignSystem · CardKit · GyeopKit · DataKit (App Clip은 Build 5에서 제외)
- [x] ✅ Mock → 실구현 배선 (CardGenerator · SwiftData · MPC(실기기)/Mock(시뮬레이터) · 클립 겹 병합)
- [x] ✅ `swift test` 110개 통과, `xcodebuild build` 시뮬레이터·실기기 모두 성공
- [x] ✅ UI 테스트 16개 통과 (온보딩→맞대기→겹→컬렉션 관통 + Dynamic Type XS/AX5 + 다크)
      — 3개는 데모 레코딩 전용이라 `TEST_RUNNER_DEMO_RECORDING=1`에서만 실행
- [x] ✅ 엣지: 교환 실패 4종 화면·재시도, 중복 겹 멱등(리포지토리), 빈 상태(ContentUnavailableView), 권한 거부→타임아웃 안내
- [x] ✅ 계정 삭제 (설정 > 계정 삭제, 심사 5.1.1(v))
- [x] ✅ 로컬 네트워크 권한 문구(NSLocalNetworkUsageDescription)·NSBonjourServices
      — 서비스명 `gyeop-exchange`가 `ExchangeConstants.serviceType`과 일치하는지 확인 완료
- [x] ✅ ITSAppUsesNonExemptEncryption = NO (MPC 암호화는 애플 제공이라 면제)
- [x] ✅ **프라이버시 매니페스트** `App/Support/PrivacyInfo.xcprivacy` — UserDefaults를 `CA92.1`로
      선언. 번들 루트 포함 확인. 없으면 업로드가 거부된다 (2024-05 이후)
- [x] ✅ App Clip 타깃·스킴·`AppClipKit` 의존이 project.yml·pbxproj·공유 스킴 어디에도 없음

## B. 실기기 검증 (기기 2대, docs/device-required.md 통합 실행 계획)

- [x] ✅ MPC 2대 왕복 + 엣지 + 햅틱 + 24h 중복 규칙 (계획 §4~7) — 2026-08-09 합격
- [x] ✅ SIWA 실사용자 플로우 (계획 §1) — 2026-08-09 합격
- [x] ✅ 카드 셰이더 60fps (계획 §3) — 2026-08-09 합격
- [x] ✅ App Group 클립→본앱 마이그레이션 (계획 §8) — 2026-08-09 합격
- [ ] **재검증 필요 (Build 5)**: 위 합격 이후 맞대기 코드가 두 군데 바뀌었다.
      저장소 강등 경로의 교환 팩토리, 그리고 MCPeerID 표시 이름의 바이트 절단
      (이모지 닉네임 크래시 방어). 시뮬레이터에서 도는 코드가 아니라 단위 테스트까지만
      확인했다 — 2대 왕복 한 번 더 돌려볼 것
- [ ] ⏳ 소유자 촬영 대기: 2대 시연 영상 5컷. 촬영 순서와 리뷰 노트 삽입 위치는 `review-kit.md` §2~3에 준비됨

## C. App Store Connect (외부 의존)

- [x] ✅ **TestFlight 업로드 완료 — `1.0 (5)`, 2026-08-22.** Apple Distribution 서명 + iOS Team
      Store 프로비저닝 프로파일로 아카이브·업로드, App Store Connect 처리 진입까지 확인
- [ ] 🔧 TestFlight 처리 완료 확인 후 테스터 배포 (ASC에서 직접)
- [x] ✅ 스크린샷 재촬영 (2026-08-22) — 6.9" 10장 `docs/screenshots/` 갱신. **이전 세트는
      Build 4 이전 UI(관심사 최대 5개·이모지 칩)라 현재 앱과 달랐다** (심사 2.3.3 위험)
- [ ] 🔧 스크린샷 ASC 업로드 (review-kit.md §1 — 7장 이내 큐레이션 권장)
- [ ] 🔧 개인정보 처리방침 게시 (docs/privacy-policy.md → 공개 URL) + 라벨 "수집 안 함"
- [ ] 🔧 리뷰 노트 + 시연 영상 URL (review-kit.md §3 초안)
- [x] ✅ 1차 제출에서 App Clip 제외. Gyeop은 Clip을 임베드하지 않으며 본앱 associated domains 자리 표시도 제거됨
- [ ] ⏳ 후속 App Clip 릴리스: 실도메인·AASA 확정 후 경험 등록 (`review-kit.md` §4)

## D. 제출 전 리스크 (2026-08-22 기준)

| # | 리스크 | 영향 | 완화 |
|---|---|---|---|
| 1 | **`UITextInputMode.activeInputModes`를 매니페스트에 선언하지 않음** (`EmojiKeyboardField`, 이모지 키보드 강제) | 필수 사유 API의 "활성 키보드" 항목에 해당. 커스텀 키보드 앱이 아니면 승인된 사유가 제한적이라, 사유를 임의로 적으면 그 자체가 반려 사유가 될 수 있어 비워 뒀다 | 애플 문서 확인 후 선언하거나, F63의 이모지 키보드 강제를 걷어낸다 (커스텀 이모지 그리드 복귀 = UX 후퇴) |
| 2 | 아카데미 이메일 검증 미구현 (스펙 ⑤ Lv2의 일부) | 폐쇄형 커뮤니티 보장 없음 — 제품 결정 필요 | 서버 없이는 불가. v1은 개방형으로 제출하고 리뷰 노트에 명시 |
| 3 | SIWA 토큰을 로컬 검증 없이 저장 (서버 부재로 검증 불가) | 보안상 실해는 없음(로컬 전용), 심사 이슈 아님 | 서버 도입 시 검증 추가 |
| 4 | `testFullFlowDarkMode`가 실제로는 라이트로 실행된다 | 다크 모드가 자동 검증되지 않는다 | 실행 전 `xcrun simctl ui <udid> appearance dark` (테스트 주석에 절차 있음) |
| 5 | ~~MPC 실기기 미검증~~ **해소 (2026-08-09)** — 단, B절의 Build 5 재검증 항목 참고 | – | – |
| 6 | ~~어소시에이티드 도메인 미확정~~ **1차 제출에서 해소** — GyeopClip 임베드와 본앱 자리 표시 entitlement를 제거 | App Clip 경험 등록은 후속 릴리스까지 보류 | 실도메인·AASA 확정 후 복원 |
| 7 | ~~앱 아이콘 리소스~~ **해소 (2026-08-09)** — AppIcon-1024.png 생성·에셋 연결 완료 (F19) | – | 클립 아이콘 항목은 App Clip 제외로 무효 |

### 이번 갱신에서 삭제한 항목 (사실이 아니었음)

- "`swift test` 63개 + AppClipKit 12개" — AppClipKit은 빌드에서 빠졌고 패키지 테스트는 110개다.
- "시즌(수료 D-day)이 MockData.season 고정" — `MockData`에 `season`이 없다.
- "Dynamic Type 접근성 확대(AX1~5)를 앱 전체에서 제거" — `App/`에 `dynamicTypeSize` 클램프가
  없고 AX5가 정상 동작한다. UI 테스트가 AX5에서 통과하는 것으로 확인.
