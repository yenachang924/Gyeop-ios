# 세션 인수인계 — Build 6 이후

작성 2026-08-22. 이 문서 하나만 읽어도 다음 세션이 이어받을 수 있게 쓴다.
제품 정의는 `gyeop-spec.md`, 세션 규칙은 루트 `CLAUDE.md`, 제출 현황은
`submission-checklist.md`를 본다.

## 1. 지금 어디까지 와 있나

| 항목 | 값 |
|---|---|
| 저장소 | https://github.com/yenachang924/Gyeop-ios |
| 작업 브랜치 | `feat/build-5-current-card` (main은 `8efcd5c`에서 그대로) |
| 앱 버전 | `1.0 (6)` |
| TestFlight | `1.0 (5)`·`1.0 (6)` 업로드 완료 (2026-08-22). **6을 쓸 것** — 5에는 활성 키보드 사유가 빠져 있다 |
| Swift Package 테스트 | 110개 통과 |
| Xcode UI 테스트 | 16개 통과 (데모 레코딩 전용 3개는 skip) |
| 빌드 | 시뮬레이터·실기기·Release 아카이브 모두 성공 |
| App Clip | Build 5부터 **제외**. 타깃·스킴·`AppClipKit` 의존 모두 없음 |

검증에 쓴 환경: Xcode 26.6 (17F113), Swift 6.3.3, iPhone 17 Pro 시뮬레이터 (iOS 26.5),
실기기 iPhone 13 Pro (iOS 26.5).

## 2. 이번 라운드에서 한 일

### Build 5 Mac 검증
- UI 테스트 5건 실패를 잡았다. 앱 결함이 아니라 테스트의 입력·스크롤 방식 문제였다
  (값이 찬 필드에 캐럿이 앞에 놓여 글자가 끼어듦, AX5에서 칩이 위쪽에 남는데 아래로만
  스와이프, 스크롤 감속에 첫 탭이 소비됨, 필드가 화면 가장자리에 걸려 탭이 시스템 제스처에 먹힘).
  단언은 약화하지 않고 오히려 추가했다.

### 관심사 화면 재작업 (소유자 지시)
- 제목을 프로토타입 원문 "요즘 나를 이루는 것"으로 (`docs/gyeop-prototype.html:477`)
- 칩을 MBTI 알약과 같은 캡슐·같은 표면으로. 외곽선 제거, 체크 아이콘 제거
- 선택 채움은 **무채 잉크**(U1). 레드는 진행 버튼 한 곳에만 — 무채는 상태, 레드는 행동
- 카운터를 내비게이션 바 툴바로 (직접 그린 페이드 띠가 경계선을 남겼다)
- 글자 급 상향: 칩·머리말 13 → 17, 주요 CTA 17 → 20
- 「지금의 나」를 한 줄 필드로 되돌림. 여러 줄이면 리턴 키가 줄바꿈으로 먹혀 `onSubmit`이
  오지 않아 다음으로 넘어갈 수 없었다. 비어 있다는 빨간 경고도 제거

### 카탈로그 개방
- 직군 나열(개발·AI·데이터 분석·엔지니어링·UX/UI·서비스 기획)을 걷어내고 관심사 28개로 재구성
- **상위 개념이 하위를 삼키던 문제 해결**: 겹침 판정이 정확한 문자열 비교
  (`CardSnapshot.sharedInterests`)라 "테크"와 "개발", "취미 생활"과 "게임"이 겹으로 안 잡혔다.
  `InterestCatalogTests`의 "no catalog name contains another"로 고정
- 카드 뒷면 관심사가 전부 ✨로 떨어지던 것 수정 (`InterestSymbol`에 카탈로그 이름이 없었다)

### 맞대기 결함 2건
- 저장소(SwiftData) 생성 실패 경로가 `makeExchangeSession`을 넘기지 않아 **실기기에서도**
  기본값인 Mock으로 떨어졌다. 가상 상대와 교환이 성사된 것처럼 보였다. 두 경로가 같은
  팩토리를 쓰도록 묶음
- `MCPeerID(displayName:)`는 UTF-8 63바이트 초과 시 예외를 던지는데 표시 이름을 **글자 수**로
  잘랐다. 닉네임에 길이 제한이 없고 가족 이모지 한 글자가 25바이트라 맞대기 진입에서 죽는다.
  판정을 `GyeopKit.makeExchangePeerName`으로 옮기고 바이트 기준 절단 + 테스트 5개로 고정

### 제출 준비물
- 프라이버시 매니페스트 신설 후 완성 — `CA92.1`(UserDefaults) + `54BD.1`(활성 키보드)
- 목업 상대의 관심사가 카탈로그 밖이라 **무엇을 골라도 겹이 잡히지 않던 것** 수정.
  데모·심사 스크린샷에 핵심 순간이 한 컷도 없었다
- App Store 스크린샷 10장 재촬영 (이전 세트는 Build 4 이전 UI였다 — 심사 2.3.3 위험)
- `submission-checklist.md`가 App Clip 시절 기준이라 코드를 확인해 정정

## 3. 남은 일 — 환경별로 갈린다

### A. 소유자만 할 수 있다 (브라우저·촬영)

1. **TestFlight `1.0 (6)` 처리 완료 확인 → 테스터 배포**
2. **스크린샷 ASC 업로드** — `docs/screenshots/` 10장 준비됨, 7장 이내 큐레이션 권장
3. **개인정보 처리방침 공개 URL 게시** (`privacy-policy.md` → 호스팅) + 데이터 라벨 "수집 안 함"
4. **ASC 메타데이터 입력** (`review-kit.md` §5 초안)
5. **2대 시연 영상 5컷 촬영** (`review-kit.md` §2)

에이전트는 App Store Connect API 자격 증명이 없어 처리 상태 조회조차 못 한다.

### B. Mac + 기기가 있어야 한다

6. **실기기 UI 자동화 테스트** — 현재 막혀 있다:
   `The test runner failed to initialize for UI testing. (Timed out while enabling automation mode.)`
   기기에서 **`설정 > 개발자 > UI 자동화 사용`** 을 켜고 잠금 해제한 상태로 다시 실행할 것.
   ```bash
   xcodebuild test -project Gyeop.xcodeproj -scheme Gyeop \
     -destination 'platform=iOS,id=<device-udid>' -allowProvisioningUpdates
   ```
7. **MPC 2대 왕복 재검증** — 위 §2의 맞대기 결함 2건은 실기기에서만 도는 코드라
   단위 테스트까지만 확인했다. 특히 이모지 닉네임 크래시 방어를 실기기에서 볼 것
8. **다크 모드 실검증** — `testFullFlowDarkMode`는 실제로는 라이트로 돈다.
   실행 전 `xcrun simctl ui <udid> appearance dark` (테스트 주석에 절차 있음)

### C. 어디서든 가능 (Windows 포함)

9. **문서와 코드의 불일치 정리** — `docs/` 전체가 App Clip 시절·Build 4 시절 서술을 갖고 있다.
   `submission-checklist.md`를 기준으로 나머지를 맞춘다. **아래 §5를 먼저 볼 것.**
10. **ASC 메타데이터·리뷰 노트 초안 다듬기** (`review-kit.md` §3·§5)

## 4. 다음 세션에 넣을 프롬프트

### Mac 세션

```
너는 iOS 앱 "겹(Gyeop)"의 Mac 세션 담당자다.

저장소: https://github.com/yenachang924/Gyeop-ios
브랜치: feat/build-5-current-card

시작 전에 반드시 읽어라:
1. 루트 CLAUDE.md (세션 규칙 — AGENTS.md는 없다. 이 파일이 그 역할이다)
2. docs/session-handoff-build-6.md (현재 상태와 남은 일)
3. docs/submission-checklist.md (제출 현황)

절대 지킬 것:
- main에 push 금지. PR 생성·병합 금지. feat/build-5-current-card로만 커밋·push
- App Clip은 제외 상태다. project.yml·pbxproj·공유 스킴에 AppClipKit / GyeopClip /
  GyeopClipUITests / GyeopClip.xcscheme가 다시 생기면 안 된다
- AppClip/ 소스 폴더는 삭제·수정하지 않는다
- pbxproj 직접 수정 금지. project.yml 고친 뒤 xcodegen generate
- 테스트를 약화시켜 통과시키지 마라. 실패하면 구현을 고친다
- 빌드·테스트를 실행하지 않았으면 통과했다고 표현하지 마라

우선 할 일 (핸드오프 §3-B):
- 기기에서 "설정 > 개발자 > UI 자동화 사용"을 켠 뒤 실기기 UI 테스트 실행
- 기기 2대가 있으면 MPC 왕복 재검증 (docs/device-required.md)
- 다크 모드는 시뮬레이터 외관을 dark로 바꾼 뒤 실행

검증 명령:
  swift test --package-path Packages/GyeopPackages
  xcodebuild test -project Gyeop.xcodeproj -scheme Gyeop \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
  xcodebuild build -project Gyeop.xcodeproj -scheme Gyeop \
    -destination 'generic/platform=iOS Simulator'

기대값: Swift Package 110개 통과, UI 테스트 16개 통과(skip 3), BUILD SUCCEEDED.

코드를 바꿔 새 빌드를 올려야 하면 project.yml의 CFBundleVersion을 7로 올리고
xcodegen generate 후 아카이브·업로드한다. TestFlight 업로드는 소유자 승인을 받고 한다.
```

### Windows·기타 세션 (빌드 불가)

```
너는 iOS 앱 "겹(Gyeop)"의 문서·리뷰 담당자다. 이 환경은 Windows다.

xcodebuild, xcodegen, swift test, 시뮬레이터, 아카이브, TestFlight 업로드는
원천적으로 불가능하다. 시도하지 마라. Swift 코드를 읽고 편집할 수는 있지만
빌드로 검증할 수 없으므로, 고쳤다면 반드시 "Mac에서 검증 필요"라고 명시하고
검증 항목을 목록으로 남겨라.

저장소: https://github.com/yenachang924/Gyeop-ios
브랜치: feat/build-5-current-card

시작 전에 반드시 읽어라:
1. 루트 CLAUDE.md
2. docs/session-handoff-build-6.md (특히 §5 — 문서와 코드가 어긋난 목록)
3. docs/submission-checklist.md

절대 지킬 것:
- main에 push 금지. PR 생성·병합 금지
- project.yml과 Gyeop.xcodeproj는 이 환경에서 건드리지 마라 (xcodegen을 못 돌린다)
- AppClip/ 폴더는 손대지 않는다
- git add . / git add -A 금지. 확인한 파일만 명시적으로 stage
- 문서를 고칠 때는 코드를 직접 확인한 사실만 쓴다. 확인 못 한 것은 "확인 필요"로
  남기고, 파일 경로와 줄 번호를 근거로 인용하라

할 일: 핸드오프 §3-C와 §5.
```

## 5. 문서와 코드가 어긋난 목록 (확인된 것)

다음 세션이 바로 손댈 수 있게 남긴다. **`submission-checklist.md`는 2026-08-22에 정정 완료.**

| 문서 | 어긋난 서술 | 코드의 사실 |
|---|---|---|
| `docs/README.md` (6군데: 7·43·44·59·62·71행) | "받는 사람은 앱이 없어도 됩니다. **App Clip**이 그 자리에서 열립니다" — 대표 기능으로 소개 | App Clip은 Build 5부터 제외. 이 문구가 App Store 설명문에 그대로 들어가면 **실제로 없는 기능을 광고**하는 셈이라 심사 위험. 루트 `README.md`에는 이 서술이 없다 |
| `implementation-scope.md` | App Clip이 "★출시" 목표로 표시됨 | 1차 제출 제외, 후속 릴리스로 보류 |
| `gyeop-prototype.html` | 관심사 "최대 5개" | 정확히 3개 (`ProfileInput.interestCount`) |
| `device-required.md` | Build 5에서 바뀐 맞대기 코드 2건이 목록에 없음 | §2 "맞대기 결함 2건" 참고 — 재검증 항목으로 추가 필요 |

`gyeop-spec.md`·`navigation-map.md`는 아직 대조하지 못했다. 관심사 개수(3), 온보딩 단계(3/3),
카드 수정 화면(1/2) 서술이 코드와 맞는지 확인이 필요하다.

## 6. 알아둘 함정

- **Core 패키지만 고치면 `xcodebuild`가 증분 빌드에서 놓친다.** 앱에 반영되지 않은 채
  "고쳤다"고 착각하기 쉽다. 패키지를 고친 뒤에는 `xcodebuild clean` 후 확인하고,
  화면 변경은 반드시 스크린샷으로 눈으로 볼 것
- **UI 테스트 스크린샷 추출**:
  `xcrun xcresulttool export attachments --path <result>.xcresult --output-path <dir>`
  후 `manifest.json`의 `suggestedHumanReadableName`으로 매핑한다
- **`gh`는 `~/.local/bin/gh`에 있다** (Homebrew 미설치라 바이너리를 직접 받았다).
  XcodeGen도 소스에서 빌드해 썼다 — Mac에 둘 다 전역 설치돼 있지 않다
- **디자인 가드레일**: `CLAUDE.md`의 정렬 스프린트 규칙은 토큰 값 변경·새 색상/폰트 도입을
  막는다. 이번 라운드의 글자 급 상향과 선택 색 변경은 **소유자 직접 지시**로 진행한 것이다
