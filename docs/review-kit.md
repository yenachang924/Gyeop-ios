# 심사 대비물 (Review Kit)

제출(App Store Connect) 때 그대로 옮겨 쓰는 재료 모음. 상태 표시: ✅ 준비됨 · 🔲 촬영/작성 필요 · ⏳ 외부 대기

## 1. 스크린샷 세트 (6.9" — iPhone 17 Pro, 세로 고정)

시뮬레이터 `Cmd+S` 캡처, 상태바 정리는 `xcrun simctl status_bar override` 사용.

| # | 화면 | 진입 방법 | 상태 |
|---|---|---|---|
| 1 | 온보딩 — 관심사 선택 | 첫 실행 → 로그인 뒤 1/3 단계 | 🔲 |
| 2 | 온보딩 — 성향 2×2 | 2/3 단계 | 🔲 |
| 3 | 카드 리빌 ("당신의 카드가 완성됐어요") | 온보딩 완주 직후 | 🔲 |
| 4 | 맞대기 — 탐색 중 | 컬렉션 우상단 맞대기 버튼 | 🔲 |
| 5 | 맞대기 — 겹 성립 (상대 카드 + 겹치는 관심사) | 시뮬레이터 Mock 교환 완료 | 🔲 |
| 6 | 컬렉션 — 카드 그리드 + D-day | 겹 2~3개 쌓은 뒤 | 🔲 |
| 7 | 카드 상세 — 겹치는 관심사 하이라이트 | 받은 카드 탭 | 🔲 |

*스크린샷 자동 촬영 스크립트는 `docs/device-required.md` 통합 실행 계획의 시뮬레이터 절차와 같은 흐름을 쓴다.*

## 2. 맞대기 2대 시연 영상 촬영 목록 (리뷰 노트 첨부용)

실기기 2대 필요 — MPC는 시뮬레이터에서 불가. 각 컷 10초 이내, 전체 60초 이내.

| 컷 | 내용 | 확인 포인트 |
|---|---|---|
| 1 | 두 기기 모두 컬렉션 → 맞대기 진입 | 양쪽 "주변 러너를 찾는 중" |
| 2 | 아이폰을 물리적으로 맞댐 | 로컬 네트워크 권한 프롬프트(첫 실행) 허용 장면 포함 |
| 3 | 연결 → 겹 성립 화면 | 3초 이내 완료, 햅틱 언급 자막 |
| 4 | 양쪽 컬렉션에 서로 카드 등장 | 겹 카운트 +1, 같은 겹 ID(중복 없음) |
| 5 | 한쪽 이탈 후 재시도 | 실패 화면(중립 톤) → "다시 맞대기" 성공 |

촬영 후: 영상 URL(비공개 YouTube/Drive)을 App Review 노트에 첨부.

## 3. 데모 계정 · 리뷰 노트

- 로그인은 **Sign in with Apple 단독**이므로 별도 아이디/비밀번호 데모 계정이 없다.
  리뷰어 본인 Apple ID로 즉시 로그인 가능 — 폐쇄형 가입 제한 없음(이메일 검증은 v1 미포함).
- 리뷰 노트 초안:
  > 겹은 Apple Developer Academy 러너용 근접 카드 교환 앱입니다. 서버 없이 모든 데이터는
  > 기기 내 저장(SwiftData/Keychain)됩니다. 카드 맞대기(MultipeerConnectivity)는 기기 2대가
  > 필요하므로 시연 영상을 첨부합니다: [영상 URL]. 시뮬레이터/기기 1대에서는 온보딩·카드
  > 생성·컬렉션·계정 삭제를 확인할 수 있습니다. 계정 삭제: 컬렉션 좌상단 설정 > 계정 삭제.
- 심사 필수 대응: 계정 삭제 ✅ (설정 > 계정 삭제, 5.1.1(v)) · 추적 없음 · 결제 없음.

## 4. App Clip 경험 등록 (App Store Connect)

⏳ 선행 대기: **어소시에이티드 도메인 실도메인 확정** + **헤더 이미지(D2 산출물)**.

등록 절차 (도메인·이미지 준비 후):
1. App Store Connect > 앱 > App Clip > 기본 경험 설정
   - 헤더 이미지: 1800×1200px, D2 산출물 (⏳)
   - 부제·액션 문구: "카드 맞대고 겹 쌓기" / 액션 "열기"
2. 고급 경험(초대 URL): `https://<실도메인>/clip?inviter=<runnerID>` — `InvocationURLParser`가
   `inviter` 파라미터를 해석한다 (AppClipKit 테스트로 검증됨).
3. 도메인 웹서버에 AASA(apple-app-site-association) 배포: `appclips` 섹션에
   `<TeamID>.com.gyeop.app.Clip`.
4. entitlements 교체: `AppClip/App/AppClip.entitlements` + `App/Support/Gyeop.entitlements`의
   `PLACEHOLDER.gyeop.example` → 실도메인 (교체 후 `xcodegen generate`).
5. 시뮬레이터 검증: 스킴 실행 인자 `_XCAppClipURL` = 위 URL (Xcode GyeopClip 스킴에서).

## 5. App Store Connect 메타데이터 초안

- 이름: 겹 / 부제: 아이폰을 맞대면, 만남이 쌓입니다
- 카테고리: 소셜 네트워킹 / 연령 등급: 4+ (수집 데이터 없음, UGC는 카드 닉네임 수준)
- 개인정보 처리방침 URL: `docs/privacy-policy.md`를 팀 웹 공간(GitHub Pages 등)에 게시 후 URL 기입 🔲
- 개인정보 라벨: 데이터가 수집되지 않음 (근거: privacy-policy.md 하단 매핑)
- 수출 규정: ITSAppUsesNonExemptEncryption = NO (Info.plist에 반영됨 ✅)
