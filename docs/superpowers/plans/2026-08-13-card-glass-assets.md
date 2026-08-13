# 카드 뒷면 분리 글라스 에셋 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카드 뒷면의 관심사 이모지를 우측 상단 Liquid Glass 버블로 분리하고, 현재 오라 위에 정적인 겹친 유리 배경을 추가한다.

**Architecture:** `CardInterestAssets`는 관심사 순서를 대표 이모지 배열로 바꾸는 순수 CardKit API다. `CardBackView`는 좌측 MBTI·이름 칩, 우측 에셋 버블, 배경 유리 타원 레이어를 전용 하위 뷰로 조립한다. 시드 기반 MeshGradient와 카드 앞면은 변경하지 않는다.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI tests, iOS 26 Liquid Glass.

## Global Constraints

- SwiftUI 100%, Swift 6 strict concurrency, `@unchecked Sendable` 및 `print` 금지.
- 커스텀 비주얼은 CardKit 안에서만 만들고, 색·폰트·간격은 기존 DesignSystem 토큰만 사용한다.
- 카드 앞면과 MBTI의 카드 세로 중앙 왼쪽 위치·크기를 바꾸지 않는다.
- 상시 반복 애니메이션을 추가하지 않는다.
- `App/Features/Card/CardRevealView.swift`의 기존 로컬 수정은 변경하지 않는다.

---

### Task 1: 우측 에셋 순서 API

**Files:**

- Create: `Packages/GyeopPackages/Sources/CardKit/CardInterestAssets.swift`
- Modify: `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`

**Interfaces:**

- Produces: `public enum CardInterestAssets { public static func symbols(for interests: [String]) -> [String] }`
- Consumes: `InterestSymbol.emoji(for:)`.

- [ ] **Step 1: Write the failing test**

```swift
@Test("관심사 순서대로 우측 에셋 심볼을 보존한다")
func preservesInterestOrder() {
    #expect(CardInterestAssets.symbols(for: ["클라이밍", "커피"]) == ["🧗", "☕"])
}
```

- [ ] **Step 2: Verify it fails**

Run `(cd Packages/GyeopPackages && swift test --filter preservesInterestOrder)`. Expected: `CardInterestAssets` is not found.

- [ ] **Step 3: Write the minimal implementation**

```swift
public enum CardInterestAssets {
    public static func symbols(for interests: [String]) -> [String] {
        interests.map(InterestSymbol.emoji(for:))
    }
}
```

- [ ] **Step 4: Verify it passes and commit**

Run `(cd Packages/GyeopPackages && swift test --filter preservesInterestOrder)`. Expected: PASS. Commit the two task files with `feat: preserve card interest asset order`.

### Task 2: 분리 Liquid Glass 버블과 겹친 카드 유리 배경

**Files:**

- Modify: `Packages/GyeopPackages/Sources/CardKit/CardView.swift:128-223`
- Test: `UITests/ScreenshotAndAccessibilityUITests.swift:60-140`

**Interfaces:**

- Consumes: `CardInterestAssets.symbols(for:)`, `DS.Typo`, `DS.Spacing`, `DS.Palette`, `DS.Radius.card`.
- Produces: 기존 `CardBackView(card:)` API와 `card.flip` identifier를 유지한다.

- [ ] **Step 1: Write the failing visual test checkpoint**

Keep the `*-9b-card-back` capture after the flip finishes. Run the single screenshot flow and inspect it: before this task, symbols remain inside left chips, which fails F76's right-top asset layout.

- [ ] **Step 2: Implement the smallest CardKit composition**

Keep only names in `interestChips` using `DS.Typo.footnote` and material capsules. Add `CardInterestAssetStack`, which reads `CardInterestAssets.symbols(for: card.interests)` and layers circular material bubbles from top-right toward lower-left, one `DS.Spacing.s` offset step per symbol. Use `DS.Typo.mbtiHero` for the symbols. Add `CardBackGlassLayers` between the MeshGradient and rectangular material: two static circles with system material, distinct existing token offsets, and no animation hooks.

- [ ] **Step 3: Verify package and UI behavior**

Run `(cd Packages/GyeopPackages && swift test)`. Expected: PASS. Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests`. Expected: PASS. Export `*-9b-card-back` attachments and inspect light, dark, and accessibility layouts.

- [ ] **Step 4: Commit**

Commit CardKit and UI test changes with `feat: layer liquid glass card interest assets`.

### Task 3: Release verification

- [ ] **Step 1: Build the app**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`. Expected: `** BUILD SUCCEEDED **` and exit code 0.

- [ ] **Step 2: Run package tests**

Run `(cd Packages/GyeopPackages && swift test)`. Expected: PASS and exit code 0.

- [ ] **Step 3: Verify full screenshots**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests`. Expected: PASS. Extract the results and inspect the card back before claiming completion.
