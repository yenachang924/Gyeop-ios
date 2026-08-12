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

### Task 1: Lock the common visual surface contract

**Files:** Modify `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`.

**Interfaces:** Consumes `CardVisual(seed:)`, `controlPoints`, and `ribbonParameters`; produces `CardVisualTests.sharedSurfaceIsStableAcrossTwoReads()`.

- [ ] **Step 1: Write the failing test**

Add to the existing CardVisual suite:

    @Test("같은 카드 표면은 재사용해도 메시와 리본이 변하지 않는다")
    func sharedSurfaceIsStableAcrossTwoReads() {
        let first = CardVisual(seed: "optical-ribbon")
        let second = CardVisual(seed: "optical-ribbon")
        #expect(first.controlPoints == second.controlPoints)
        #expect(first.ribbonParameters == second.ribbonParameters)
    }

- [ ] **Step 2: Verify RED**

Run `cd Packages/GyeopPackages && swift test --filter CardVisualTests.sharedSurfaceIsStableAcrossTwoReads` before adding the test. Expected: FAIL because the test is absent.

- [ ] **Step 3: Add exactly the shown test**

No production change is needed: the existing deterministic API is the desired source.

- [ ] **Step 4: Verify GREEN**

Run `cd Packages/GyeopPackages && swift test --filter CardVisualTests.sharedSurfaceIsStableAcrossTwoReads`. Expected: PASS.

- [ ] **Step 5: Commit**

Commit only the test with message `test: lock card optical ribbon surface`.

### Task 2: Replace F76 objects with the common mesh surface

**Files:** Modify `Packages/GyeopPackages/Sources/CardKit/CardView.swift:145-287`; delete `Packages/GyeopPackages/Sources/CardKit/CardInterestAssets.swift`.

**Interfaces:** Consumes `CardVisual(seed: card.seed).colors`, `CardVisual.meshDimension`, and `CardBackView.gridPoints`; produces a `CardBackView` using one clipped `MeshGradient` and Material finish, without F76 helpers.

- [ ] **Step 1: Confirm the rejected objects are present**

Run `rg -n "CardBackGlassLayers|CardInterestAssetStack|CardInterestAssetSurface" Packages/GyeopPackages/Sources/CardKit/CardView.swift`. Expected: declarations and uses are found.

- [ ] **Step 2: Apply the smallest visual replacement**

Add `meshColors` initialized from `CardVisual(seed: card.seed).colors` to `CardBackView`. Its background becomes a `ZStack` of `MeshGradient(width: CardVisual.meshDimension, height: CardVisual.meshDimension, points: Self.gridPoints, colors: meshColors)` and `Rectangle().fill(.ultraThinMaterial)`. Delete the top-trailing interest overlay plus `CardBackGlassLayers`, `CardInterestAssetStack`, `CardInterestAssetSurface`, and the unused `CardInterestAssets.swift`. Preserve the central-leading MBTI and interest-name capsule stack.

- [ ] **Step 3: Verify the replacement**

Run `rg -n "CardBackGlassLayers|CardInterestAssetStack|CardInterestAssetSurface" Packages/GyeopPackages/Sources/CardKit/CardView.swift; cd Packages/GyeopPackages && swift test`. Expected: no `rg` matches and all package tests PASS.

- [ ] **Step 4: Commit**

Stage CardView and remove the unused helper file. Commit message: `feat: restore continuous card ribbon surface`.

### Task 3: Validate on the target simulator

**Files:** Modify `docs/superpowers/plans/2026-08-13-card-optical-ribbon.md`.

**Interfaces:** Consumes final CardKit implementation and `GyeopUITests/ScreenshotAndAccessibilityUITests`; produces screenshot-reviewed final rendering and checked verification record.

- [ ] **Step 1: Build**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`. Expected: direct exit code 0 and `BUILD SUCCEEDED`.

- [ ] **Step 2: Run the card UI flow and inspect attachments**

Run `xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests`. Expected: all cases pass. Extract and inspect front, back, dark-mode, and accessibility-size PNG attachments.

- [ ] **Step 3: Mark verified and commit**

Check every completed box after the successful runs, then commit this plan with message `docs: verify optical ribbon card`.
