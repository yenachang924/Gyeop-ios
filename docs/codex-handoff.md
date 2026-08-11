# 겹(Gyeop) — 업무 이관 문서 (Codex용)

작성: 2026-08-12, 카드 리디자인·MBTI 스프린트(F54~F65) 종료 시점.
레포: `~/orca/workspaces/Gyeop-ios/bocaccio` · 브랜치 `design-gyeop-visual-update`.
이 문서는 ① 심사 리스크 분석, ② 기술 아티클 소재, ③ 다음 에이전트(Codex)에게 넘기는
작업 프롬프트, 세 부분으로 구성된다.

---

## 1. 심사 리스크 분석 (2026-08-12 전수 감사 결과)

### 통과 (근거 확인 완료)

| 항목 | 판정 | 근거 |
|---|---|---|
| 5.1.1(v) 계정 삭제 | OK | `SettingsView` 삭제 버튼 + alert → `AccountDeletionService` → 프로필·카드·겹 전량 삭제 + Keychain 토큰 삭제. 테스트 존재 |
| 4.8 Sign in with Apple | OK | SIWA 단독(타사 로그인 없음). entitlement 존재 |
| 권한 문구 | OK | `NSLocalNetworkUsageDescription` + `NSBonjourServices`(project.yml), 서비스명 코드와 일치. 그 외 권한 사용 없음 |
| 트래킹·서드파티 SDK | OK | 외부 의존성 0, OSLog만, `ITSAppUsesNonExemptEncryption: false`. "Data Not Collected" 라벨 정합 |
| MBTI 콘텐츠 | OK | 4글자 코드만, 별명·궁합·진단 표현 없음, 건너뛰기 상시 |
| 1.2 UGC (부분 해소) | 완화됨 | **받은 카드 개별 삭제 F65로 구현됨** (contextMenu + 확인 alert). 잔여: 리뷰 노트에 "1:1 근접 교환, 공개 노출 없음" 명시, 연령 등급 12+ 상향 검토 |

### 제출 전 반드시 처리 (우선순위순)

1. **PLACEHOLDER 도메인 제거** — 클립 1차 제출 제외는 다른 브랜치(`claude/gyeop-ios-device-validation-2yh9p6`)에서 project.yml 1줄로 처리했지만, **본앱 `App/Support/Gyeop.entitlements`의 associated-domains(applinks·appclips)에 `PLACEHOLDER.gyeop.example` 2줄이 남아 있다.** 함께 제거 후 `xcodegen generate`. 자리 표시 도메인은 서명·업로드 이슈를 만든다.
2. **2대 시연 영상** — 심사관 기기에서는 맞대기 상대가 없어 타임아웃된다. 실기기 2대 교환 영상 촬영 → 리뷰 노트에 URL 첨부 (`docs/review-kit.md` §3 초안 있음, `docs/submission-checklist.md` 🔲).
3. **개인정보 처리방침 공개 URL 게시** — 내용은 `docs/privacy-policy.md`로 완성. 게시 + ASC 기입. 문의처 개인 gmail → 팀 주소 교체.
4. 잔여 소소한 것: `MockData.referenceDate` 시점 확인, 클립 아이콘 (submission-checklist 리스크 #5·#7), SIWA 요청 스코프 `.fullName, .email`을 빈 배열로 축소(데이터 최소화, 리젝 사유는 아님).

### 브랜치 머지 주의

`design-gyeop-visual-update`(이 브랜치)와 `claude/gyeop-ios-device-validation-2yh9p6`의 머지 시 충돌 예상 지점:
- 그 브랜치는 `StyleStepView.swift`를 수정했는데 이 브랜치는 **삭제**했다 (MBTI 화면으로 교체). 이 브랜치가 이긴다.
- 그 브랜치 커밋 메시지가 "F54"를 App Clip 제출 제외에 썼는데, 이 브랜치의 docs는 F54를 카드 리디자인에 썼다. **docs/design-decisions.md 기준(이 브랜치)이 정본** — 머지 시 그쪽 결정은 별도 번호로 재기입.

---

## 2. 기술 아티클 소재 (이번 스프린트 산출)

`tech-article-plan.md`의 원칙(측정 포인트를 먼저 심는다, 틀린 가설을 먼저 쓴다)에 맞는 소재들.
각 소재는 "겪은 문제 → 탈락시킨 대안 → 수치/근거"의 골격이 이미 docs에 남아 있다.

1. **결정론적 정체성 카드: 같은 입력 = 같은 카드** — sha256 시드 → SplitMix64 → MeshGradient 25점. 프리뷰와 저장본이 픽셀 동일해야 하는 계약, ownerID를 시드에서 뺀 이유(온보딩 실시간 프리뷰). `CardKitTests`의 결정성 테스트가 증거.
2. **파스텔에서 대비를 지키는 수학** — 흰 텍스트 4.5:1 보정(명도를 깎는다) → 오라 파스텔 개정에서 **보정 방향을 반전**(잉크 기준, 명도를 올리고 채도를 뺀다). WCAG 상대 휘도 계산을 HSB 위에서 돌리는 구현. 100개 시드 전수 대비 테스트.
3. **디자인 왕복이 코드가 되는 과정: F1~F65 결정 로그** — 소유자 피드백을 F-번호로 축적해 docs를 단일 진실로 삼는 프로세스 자체. "무작위 7색 → 4색 코너 보간"처럼 같은 주제가 4번 뒤집힌 기록(F21→F24→F25→F56→F61)이 그대로 남아 있다.
4. **원형 색상환에서의 그라디언트 보간** — hue를 선형 보간하면 빨강↔보라 사이에서 무지개를 돈다. 벡터 합(atan2) 원형 보간 + 인접 hue 스윕(0.08~0.15)으로 레퍼런스의 "큰 면이 흐르는" 오라를 만든 과정.
5. **SwiftUI에 없는 API: 이모지 키보드** — `keyboardType`에 이모지가 없다. `UITextInputMode` 오버라이드로 시스템 이모지 키보드를 여는 UIKit 래핑 최소화 전략(F63), "고르면 키보드가 닫힌다"는 인터랙션 결정(F64).
6. **매 프레임 재계산 병목 잡기 (F49)** — KeyframeAnimator 콘텐츠 클로저 안에서 sha256+보정 루프가 돌던 사고. Signpost/Instruments로 잡는 과정 + "애니메이션은 실제로 변하는 뷰에만"(F46) 규칙이 만들어진 이유.
7. **스크린샷을 CI 산출물로** — XCUITest 풀 플로우 + xcresult attachment 추출로 라이트·다크·Dynamic Type 극단의 화면 인벤토리를 자동 생성하는 파이프라인 (`review-kit.md`).
8. (백엔드 합류 시) `tech-article-plan.md`의 B-2 오프라인 교환 멱등성 — 결정적 GyeopID는 이미 구현·테스트되어 있다.

---

## 3. Codex 이관 프롬프트

아래 블록을 Codex 세션의 첫 프롬프트로 그대로 사용.

```
너는 iOS 앱 "겹(Gyeop)"의 개발 세션을 이어받는다.

## 레포와 브랜치
- 경로: ~/orca/workspaces/Gyeop-ios/bocaccio (git worktree)
- 브랜치: design-gyeop-visual-update — 카드 리디자인·MBTI 스프린트(F54~F65)가 완료된 상태
- 메인 체크아웃 ~/orca/Gyeop-ios는 다른 브랜치다. 이 워크트리에서만 작업하라.

## 규칙 (요약 — 전문은 CLAUDE.md)
1. 기획·디자인의 단일 진실은 docs/다. 특히 docs/design-decisions.md의 F-번호 결정을
   재논의 없이 따른다. 코드와 docs가 다르면 docs가 맞다. 새 결정은 다음 F-번호로 기록한다.
2. SwiftUI 100%, Swift 6 strict concurrency, @unchecked Sendable 금지.
3. 모든 색·폰트·간격은 DesignSystem 토큰(Packages/GyeopPackages/Sources/DesignSystem/Tokens.swift).
   뷰 코드에 리터럴 금지. 커스텀 비주얼은 CardKit 안에서만.
4. 애니메이션은 실제로 변하는 뷰에만 (F46). 컨테이너에 .animation(value:) 금지.
   모든 모션은 실제 SwiftUI 스프링 기반, 기조는 무바운스 유동(예외는 F62 letterPop뿐).
5. print 금지, OSLog(Core/Telemetry.swift)만.
6. 에러는 최종 호출부에서만 catch. 중간 계층은 throws 전파.
7. 커밋 전 반드시: xcodebuild -project Gyeop.xcodeproj -scheme Gyeop
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 통과
   + (cd Packages/GyeopPackages && swift test) 통과. 둘 다 확인 후 커밋.
   xcodebuild 결과를 파이프로 가리지 말 것 — exit code를 직접 확인하라.
8. project.yml 수정 후에는 xcodegen generate. pbxproj 직접 수정 금지.
9. 사용자 노출 카피에 em-dash(—) 금지. 시뮬레이터 기준 iPhone 17 Pro (iOS 26.5).
10. UI 검증은 GyeopUITests/ScreenshotAndAccessibilityUITests 풀 플로우 실행 후
    xcresult attachment로 스크린샷을 추출해 눈으로 확인한다.

## 현재 상태 (완료된 것)
- 온보딩: 1/3 관심사(카테고리 구획·컴팩트 칩·레드 카운터) → 2/3 MBTI(3컬럼 레드 토글,
  탭 시 배경 bloom, 건너뛰기) → 3/3 닉네임·한줄·이모지(시스템 이모지 키보드 필드,
  고르면 자동 닫힘)
- 카드: 오라 파스텔 4색 코너 보간(CardVisual), 유리 카드 앞뒤(CardFlipView),
  뒷면 유리 MBTI 글자 + 세로 관심사 칩, 잉크 텍스트 대비 4.5:1 자동 보정
- 홈 "나의 카드": 제목+설정 한 줄 헤더, 카드 플립 직결(300pt), 받은 카드 그리드,
  받은 카드 길게 눌러 삭제(F65), 하단 맞대기 CTA
- 시트 블러 통일, 겹 결과 담백화, 다크 모드 전 화면 검증 완료

## 우선 작업 (순서대로)
1. 본앱 entitlements(App/Support/Gyeop.entitlements)의 PLACEHOLDER.gyeop.example
   associated-domains 2줄 제거 (클립 1차 제출 제외의 마무리 — docs/codex-handoff.md §1 참조)
2. 실기기 피드백 반영 대기 — 소유자가 실기기 테스트 중. 피드백이 오면 F66+로 기록하며 반영
3. docs/submission-checklist.md의 🔲 항목 소거 (시연 영상은 소유자 촬영, 너는 준비물 정리)
4. 리뷰 노트 초안 갱신 (docs/review-kit.md §3): 1:1 근접 교환 특성, 시뮬레이터 Mock 경로 설명
5. 여유 시: SIWA 요청 스코프 축소([]), 받은 카드 삭제를 CardDetailView 툴바에도 노출 검토

## 하지 말 것
- DesignSystem 토큰 기존 값 임의 변경, 새 색·폰트 도입 (소유자 지시 없이)
- WelcomeView 레이아웃·타이포·색 변경 (소유자 Figma 확정본)
- 보안 구조 변경 (발견 이슈는 docs/security-backlog.md에 기록만)
- 다른 워크트리·브랜치 수정
```

---

## 부록: 이번 스프린트 커밋 목록

- `c99c09c` F54~F60 카드 리디자인·MBTI 라운드 (모델 교체·오라·유리 카드·개명)
- `2b620af` F61 4색 코너 오라, MBTI 3컬럼 레드, 홈 카드 플립 직결
- `ded0626` F62 CTA 전폭 통일 + 홈 카드 300pt + MBTI 선택 스프링
- `57c517c` F63 이모지 칸 연락처 포스터 방식 (시스템 이모지 키보드)
- `026dbd9` F64 이모지 키보드 자동 닫힘 + 관심사 칩 -20% + 다크 점검
- (이 커밋) F65 CTA 블러 바·긴 이름 제외·홈 헤더 정렬·받은 카드 삭제·유리 MBTI 글자·완료 버튼 전면 은퇴
