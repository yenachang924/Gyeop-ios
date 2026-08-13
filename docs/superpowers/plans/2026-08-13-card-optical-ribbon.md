# Card Optical Ribbon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rejected circular glass composition with one deterministic optical-ribbon card surface shared by both card sides.

**Architecture:** `CardVisual` remains the seed-to-visual boundary. Its existing 5×5 mesh colors and deterministic ribbon parameters feed both card sides; the back no longer creates independent circular Material objects.

**Tech Stack:** Swift 6, SwiftUI `MeshGradient`, Swift Testing, CardKit, DesignSystem.

## Global Constraints

- Work only in this worktree and preserve the unrelated local `App/Features/Card/CardRevealView.swift` edit.
- SwiftUI only, Swift 6 strict concurrency, no `@unchecked Sendable` and no `print`.
- Custom visual work stays in CardKit. Add no image assets, HTML/CSS, colors, fonts, tokens, or background animation.
- Retain the 5×5 mesh, 4.5:1 contrast, Dynamic Type, flip, and accessibility contracts.
- Verify package tests, iPhone 17 Pro build, and `ScreenshotAndAccessibilityUITests` attachment screenshots.

---

### Task 1: Lock the card-back accessibility regression

**Files:** Modify `UITests/ScreenshotAndAccessibilityUITests.swift`.

**Interfaces:** Consumes the existing full-flow card flip. Produces an assertion that removed decorative F76 asset bubbles no longer duplicate the card-back accessibility tree.

- [x] **Step 1: Write the failing test**

Immediately after the existing `card.flip` tap and delay in `runFullFlow`, add:

    XCTAssertFalse(
        app.descendants(matching: .any)["관심사 (interests[index])"].exists,
        "뒷면의 장식 이모지는 별도 접근성 요소가 아니어야 한다"
    )

- [x] **Step 2: Verify RED**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests/testFullFlowWithScreenshots`. Expected: FAIL because F76 creates the matching decorative asset element.

- [x] **Step 3: Keep the assertion while replacing F76 in Task 2**

The test exercises the accessibility tree users receive, not a source-level implementation detail.

- [x] **Step 4: Verify GREEN**

Run the same focused UI test after Task 2. Expected: PASS.

- [x] **Step 5: Commit**

Commit the test with the Task 2 implementation, because the red test must not remain in the branch.

### Task 2: Replace F76 objects with the common mesh surface

**Files:** Modify `Packages/GyeopPackages/Sources/CardKit/CardView.swift:145-287`; delete `Packages/GyeopPackages/Sources/CardKit/CardInterestAssets.swift`.

**Interfaces:** Consumes `CardVisual(seed: card.seed).colors`, `CardVisual.meshDimension`, and `CardBackView.gridPoints`; produces a `CardBackView` using one clipped `MeshGradient` and Material finish, without F76 helpers.

- [x] **Step 1: Confirm the rejected objects are present**

Run `rg -n "CardBackGlassLayers|CardInterestAssetStack|CardInterestAssetSurface" Packages/GyeopPackages/Sources/CardKit/CardView.swift`. Expected: declarations and uses are found.

- [x] **Step 2: Apply the smallest visual replacement**

Add `meshColors` initialized from `CardVisual(seed: card.seed).colors` to `CardBackView`. Its background becomes a `ZStack` of `MeshGradient(width: CardVisual.meshDimension, height: CardVisual.meshDimension, points: Self.gridPoints, colors: meshColors)` and `Rectangle().fill(.ultraThinMaterial)`. Delete the top-trailing interest overlay plus `CardBackGlassLayers`, `CardInterestAssetStack`, `CardInterestAssetSurface`, and the unused `CardInterestAssets.swift`. Preserve the central-leading MBTI and interest-name capsule stack.

- [x] **Step 3: Verify the replacement**

Run `rg -n "CardBackGlassLayers|CardInterestAssetStack|CardInterestAssetSurface" Packages/GyeopPackages/Sources/CardKit/CardView.swift; cd Packages/GyeopPackages && swift test`. Expected: no `rg` matches and all package tests PASS.

- [x] **Step 4: Commit**

Stage CardView and remove the unused helper file. Commit message: `feat: restore continuous card ribbon surface`.

### Task 3: Validate on the target simulator

**Files:** Modify `docs/superpowers/plans/2026-08-13-card-optical-ribbon.md`.

**Interfaces:** Consumes final CardKit implementation and `GyeopUITests/ScreenshotAndAccessibilityUITests`; produces screenshot-reviewed final rendering and checked verification record.

- [x] **Step 1: Build**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`. Expected: direct exit code 0 and `BUILD SUCCEEDED`.

- [x] **Step 2: Run the card UI flow and inspect attachments**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests`. Expected: all cases pass. Extract and inspect front, back, dark-mode, and accessibility-size PNG attachments.

- [x] **Step 3: Mark verified and commit**

The full iPhone 17 Pro UI suite passed with seven tests and its card front, card back, dark-mode card back, and AX5 card back attachments were inspected. The attempted extra blurred capsule overlay was rejected because the focused UI flow timed out at the first screen; the final implementation remains the static, shared `CardVisual` ribbon mesh with no additional per-frame compositing.
