# 카드 정보 포스터·글라스 크롬 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카드 뒷면을 관심사 이모지 포스터로 만들고, 중앙 MBTI 선택·원형 글라스 설정·홈 카드 유휴 렌더 절감을 적용한다.

**Architecture:** CardKit이 관심사 이름을 대표 이모지로 바꾸는 순수 API와 카드 뒷면 레이아웃을 소유한다. App은 온보딩 선택 묶음의 정렬, 시스템 설정 버튼 표면, 정지 쉬머만 조립한다. 카드 플립은 정지 중 현재 면 하나만 보존하고 플립 중에만 두 면을 합성한다.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI tests, iOS 26 Liquid Glass.

## Global Constraints

- SwiftUI 100%, Swift 6 strict concurrency, `@unchecked Sendable` 및 `print` 금지.
- 색·폰트·간격은 기존 DesignSystem 토큰만 사용한다.
- 사용자 노출 카피에 em dash를 쓰지 않는다.
- 애니메이션은 실제 변하는 뷰에만 붙이고, 시스템 스프링과 Reduce Motion 동작을 유지한다.
- `App/Features/Card/CardRevealView.swift`의 기존 로컬 수정은 이 작업에서 건드리지 않는다.
- 커밋 전 iPhone 17 Pro 앱 빌드와 패키지 전체 테스트를 직접 통과시키고, 전체 UI 스크린샷 플로우를 눈으로 확인한다.

---

### Task 1: 관심사 대표 이모지의 순수 CardKit API

**Files:**
- Create: `Packages/GyeopPackages/Sources/CardKit/InterestSymbol.swift`
- Modify: `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`

**Interfaces:**
- Produces: `public enum InterestSymbol { public static func emoji(for interest: String) -> String }`
- Consumes: `CardBackView`가 관심사 이름을 전달한다.

- [ ] **Step 1: 실패하는 단위 테스트를 쓴다**

```swift
@Suite("InterestSymbol — 카드 관심사 에셋")
struct InterestSymbolTests {
    @Test("카탈로그 관심사는 고정 대표 이모지를 낸다")
    func knownInterestUsesCatalogSymbol() {
        #expect(InterestSymbol.emoji(for: "탁구") == "🏓")
        #expect(InterestSymbol.emoji(for: "코딩") == "💻")
    }

    @Test("미등록 관심사는 공통 반짝임으로 폴백한다")
    func unknownInterestUsesFallbackSymbol() {
        #expect(InterestSymbol.emoji(for: "새 관심사") == "✨")
    }
}
```

- [ ] **Step 2: 실패를 확인한다**

Run: `(cd Packages/GyeopPackages && swift test --filter InterestSymbolTests)`

Expected: `InterestSymbol`을 찾지 못해 컴파일 실패.

- [ ] **Step 3: 최소 구현을 쓴다**

`InterestSymbol.swift`에 App 번들의 CSV와 같은 이름·이모지 쌍을 정적 `[String: String]` 사전으로 둔다. `emoji(for:)`는 `symbols[interest] ?? "✨"`만 반환한다. App 모듈이나 번들 리소스를 import하지 않는다.

- [ ] **Step 4: 단위 테스트가 통과하는지 확인한다**

Run: `(cd Packages/GyeopPackages && swift test --filter InterestSymbolTests)`

Expected: PASS.

- [ ] **Step 5: 커밋한다**

```bash
git add Packages/GyeopPackages/Sources/CardKit/InterestSymbol.swift Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift
git commit -m "feat: add deterministic card interest symbols"
```

### Task 2: 레퍼런스형 카드 뒷면과 유휴 플립 렌더링

**Files:**
- Modify: `Packages/GyeopPackages/Sources/CardKit/CardView.swift:128-262`
- Modify: `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`

**Interfaces:**
- Consumes: `InterestSymbol.emoji(for:)`.
- Produces: 기존 `CardBackView(card:)`, `CardFlipView(card:)`의 공개 호출 형식을 유지한다.

- [ ] **Step 1: 실패하는 카드 관심사 형식 테스트를 쓴다**

```swift
@Test("관심사 칩 접근성 문구는 대표 이모지와 이름을 함께 담는다")
func interestChipLabelIncludesSymbolAndName() {
    #expect(InterestSymbol.emoji(for: "탁구") + " 탁구" == "🏓 탁구")
}
```

- [ ] **Step 2: 실패를 확인한다**

Run: `(cd Packages/GyeopPackages && swift test --filter interestChipLabelIncludesSymbolAndName)`

Expected: Task 1 이전에는 `InterestSymbol` 부재로 실패한다. Task 1 뒤에는 카드 뷰가 아직 이 API를 사용하지 않으므로 UI 검증이 다음 단계의 실패 기준이다.

- [ ] **Step 3: 최소 레이아웃과 플립 구현을 쓴다**

`CardBackView`의 바깥 프레임을 `.topLeading`으로 맞추고, MBTI 다음에 `Text("\\(InterestSymbol.emoji(for: interest)) \\(interest)")` 세로 칩을 둔다. 기존 `DS.Typo.footnote`, `DS.Spacing.s`, `DS.Spacing.xs`, material capsule을 유지한다.

`CardFlipView`는 `@State private var displayedSide`와 `@State private var isFlipping`을 쓴다. Reduce Motion에서는 `displayedSide.toggle()`만 수행한다. 일반 탭에서는 `isFlipping = true`로 양 면을 ZStack에 넣고 `DS.Motion.flip`으로 회전한 뒤, 0.55초가 끝나면 반대 면을 `displayedSide`로 확정하고 `isFlipping = false`로 이전 면을 제거한다. 비동기 완료 작업은 취소 가능한 `.task(id:)` 경로로 한 번만 실행하며 중간 계층에서 오류를 잡지 않는다.

- [ ] **Step 4: 패키지 테스트가 통과하는지 확인한다**

Run: `(cd Packages/GyeopPackages && swift test)`

Expected: PASS.

- [ ] **Step 5: 커밋한다**

```bash
git add Packages/GyeopPackages/Sources/CardKit/CardView.swift Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift
git commit -m "feat: present card details as interest poster"
```

### Task 3: 중앙 MBTI 선택, 원형 글라스 설정, 정지 쉬머

**Files:**
- Modify: `App/Features/Onboarding/MBTIStepView.swift:44-68`
- Modify: `App/Features/Collection/CollectionView.swift:91-229`
- Modify: `UITests/ScreenshotAndAccessibilityUITests.swift:40-95`

**Interfaces:**
- Consumes: `DS.Layout.homeMyCardMaxWidth`, `DS.minTapTarget`, `DS.Palette` 및 기존 UI identifiers.
- Produces: `collection.settings`, `onboarding.mbti.*`, `card.flip` 식별자를 보존한다.

- [ ] **Step 1: 실패하는 UI 테스트 어설션을 쓴다**

`ScreenshotAndAccessibilityUITests.testFullFlowWithScreenshots()`의 컬렉션 진입 뒤 설정 버튼 존재와 `card.flip` 탭 뒤 뒷면 스냅을 명시적으로 확인한다. `testSelectionStatesCapture()`에는 MBTI의 세로 선택 열 캡처를 유지한다.

```swift
XCTAssertTrue(app.buttons["collection.settings"].isHittable)
let card = app.descendants(matching: .any)["card.flip"].firstMatch
XCTAssertTrue(card.isHittable)
card.tap()
snap(app, "\(prefix)-5b-my-card-back")
```

- [ ] **Step 2: 실패를 확인한다**

Run: `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests/testFullFlowWithScreenshots`

Expected: 새 카드 뒷면 스냅 시점 또는 구현 전 미정렬 상태를 확인할 수 있는 RED 결과.

- [ ] **Step 3: 최소 화면 구현을 쓴다**

MBTI의 네 `pairRow`를 감싼 VStack만 `DS.Layout.homeMyCardMaxWidth` 너비로 제한한 뒤 부모 폭 중앙에 둔다. 제목은 기존 leading 정렬이다.

설정 label은 최소 44pt `Circle` 내부에 둔다. iOS 26에서는 `.glassEffect(.regular, in: Circle())`, 이전 OS에서는 `.background(.ultraThinMaterial, in: Circle())`와 `.overlay(Circle().strokeBorder(.quaternary))`를 사용한다.

`ShimmerFrame`은 `@State`, `onAppear`, `withAnimation`, `rotationEffect`를 제거하고 동일한 AngularGradient와 token opacity를 고정 테두리로만 그린다.

- [ ] **Step 4: UI 테스트와 빌드를 확인한다**

Run: `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests/testFullFlowWithScreenshots`

Expected: PASS, xcresult에 새 카드 뒷면 첨부 포함.

- [ ] **Step 5: 커밋한다**

```bash
git add App/Features/Onboarding/MBTIStepView.swift App/Features/Collection/CollectionView.swift UITests/ScreenshotAndAccessibilityUITests.swift
git commit -m "feat: center MBTI choices and strengthen home glass"
```

### Task 4: 전체 검증과 TestFlight 빌드 준비

**Files:**
- Modify: `App/Support/Info.plist` only if build number is not already `3`.
- Modify: `docs/submission-checklist.md` only for actually completed preparatory items.

- [ ] **Step 1: 현재 빌드 번호를 검사한다**

Run: `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' App/Support/Info.plist`

Expected: `2`이면 `3`으로 올리고, 이미 `3`이면 변경하지 않는다.

- [ ] **Step 2: 전체 빌드와 패키지 테스트를 실행한다**

Run: `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

Expected: `** BUILD SUCCEEDED **` 및 exit code 0.

Run: `(cd Packages/GyeopPackages && swift test)`

Expected: PASS 및 exit code 0.

- [ ] **Step 3: 전체 UI 스크린샷 흐름을 실행하고 첨부를 추출한다**

Run: `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests`

Expected: PASS.

`xcresulttool`로 attachment PNG를 추출해 카드 앞뒤, 다크 모드, 접근성 크기를 육안 확인한다.

- [ ] **Step 4: 최종 커밋한다**

```bash
git add App/Support/Info.plist docs/submission-checklist.md
git commit -m "chore: prepare TestFlight build 3"
```
