# 제출 체크리스트 (App Store Connect)

상태: ✅ 완료 · 🔧 이 레포에서 준비됨(외부 작업 남음) · ⏳ 외부 의존 대기 · 🔲 미착수

## A. 코드·빌드 (레포에서 완결)

- [x] ✅ 4개 세션 작업 통합 (CardKit → DataKit → GyeopKit → AppClip, 패키지별 커밋)
- [x] ✅ Mock → 실구현 배선 (CardGenerator · SwiftData · MPC(실기기)/Mock(시뮬레이터) · 클립 겹 병합)
- [x] ✅ `swift test` 63개 + AppClipKit 12개 통과, `xcodebuild build` 성공
- [x] ✅ UI 테스트: 온보딩→맞대기→겹→컬렉션 관통 + Dynamic Type XS/AX5 3종
- [x] ✅ 엣지: 교환 실패 4종 화면·재시도, 중복 겹 멱등(리포지토리), 빈 상태(ContentUnavailableView), 권한 거부→타임아웃 안내
- [x] ✅ 계정 삭제 (설정 > 계정 삭제, 심사 5.1.1(v))
- [x] ✅ 로컬 네트워크 권한 문구(NSLocalNetworkUsageDescription)·NSBonjourServices
- [x] ✅ ITSAppUsesNonExemptEncryption = NO
- [x] ✅ App Clip 타깃(GyeopClip) 활성화·본앱 임베드·App Group entitlements

## B. 실기기 검증 (기기 2대, docs/device-required.md 통합 실행 계획)

- [x] ✅ MPC 2대 왕복 + 엣지 + 햅틱 + 24h 중복 규칙 (계획 §4~7) — 2026-08-09 합격
- [x] ✅ SIWA 실사용자 플로우 (계획 §1) — 2026-08-09 합격
- [x] ✅ 카드 셰이더 60fps (계획 §3) — 2026-08-09 합격
- [x] ✅ App Group 클립→본앱 마이그레이션 (계획 §8) — 2026-08-09 합격
- [ ] 🔲 2대 시연 영상 5컷 (review-kit.md §2)

## C. App Store Connect (외부 의존)

- [ ] ⏳ Apple Developer Program 팀·번들 ID(com.gyeop.app, .Clip) 등록 확인
- [ ] 🔲 앱 레코드 생성 + 메타데이터 (review-kit.md §5 초안 그대로)
- [ ] 🔧 스크린샷 업로드 — 6.9" 10장 `docs/screenshots/` 준비됨, ASC 업로드만 남음 (review-kit.md §1)
- [ ] 🔧 개인정보 처리방침 게시 (docs/privacy-policy.md → 공개 URL) + 라벨 "수집 안 함"
- [ ] 🔧 리뷰 노트 + 시연 영상 URL (review-kit.md §3 초안)
- [ ] ⏳ App Clip 경험 등록 — 헤더 이미지 ✅ 준비됨(`docs/assets/appclip-header.png`), **실도메인·AASA** 대기 (review-kit.md §4)
- [ ] ⏳ entitlements PLACEHOLDER.gyeop.example → 실도메인 교체 후 재빌드
- [ ] 🔲 Archive → TestFlight 업로드 → 제출

## D. 제출 전 리스크 (2026-08-08 기준)

| # | 리스크 | 영향 | 완화 |
|---|---|---|---|
| 1 | ~~**MPC 실기기 미검증**~~ **해소 (2026-08-09)** — 2대 왕복·엣지 4종·24h 중복 전부 실기기 합격 | – | – |
| 2 | **어소시에이티드 도메인 미확정** — entitlements가 자리 표시 | App Clip 경험 등록 불가, 자리 표시 도메인은 서명·검증 실패 | 도메인 확정까지 App Clip을 1차 제출에서 빼는 선택지 검토 (project.yml에서 GyeopClip 의존 제거는 1줄) |
| 3 | 아카데미 이메일 검증 미구현 (스펙 ⑤ Lv2의 일부) | 폐쇄형 커뮤니티 보장 없음 — 제품 결정 필요 | 서버 없이는 불가. v1은 개방형으로 제출하고 리뷰 노트에 명시 |
| 4 | SIWA 토큰을 로컬 검증 없이 저장 (서버 부재로 검증 불가) | 보안상 실해는 없음(로컬 전용), 심사 이슈 아님 | 서버 도입 시 검증 추가 |
| 5 | 시즌(수료 D-day)이 MockData.season 고정 | 실제 기수 날짜와 불일치 | 제출 전 Core MockData.season 값을 실기수로 갱신 (1줄) |
| 6 | 온보딩 카피·emoji CSV가 스펙 기반 임시본 | 원본 프로토타입과 차이 가능 | 원본 수급 시 교체 (memory: missing-prototype-assets) |
| 7 | ~~앱 아이콘 리소스~~ **해소 (2026-08-09)** — AppIcon-1024.png 생성·에셋 연결 완료 (F19). **클립 타깃 아이콘은 별도 확인 필요** | 클립 아이콘 누락 시 업로드 경고 | 제출 전 GyeopClip 에셋 확인 |
| 8 | Dynamic Type 접근성 확대(AX1~5)를 앱 전체에서 제거 (이번 세션 제품 결정, `.dynamicTypeSize(...xxxLarge)`) | 저시력 등 접근성 확대 사용자는 큰 텍스트를 못 씀 — HIG 권고 위반이나 심사 거절 사유는 아님 | 의도된 제품 결정으로 기록. 재도입 원하면 `App/GyeopApp.swift`의 해당 modifier만 제거 |
