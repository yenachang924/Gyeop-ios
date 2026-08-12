# F72 Ribbon Wallpaper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render each deterministic identity card as a varied Apple-wallpaper field of two broad crossing pastel ribbons.

**Architecture:** `CardVisual(seed:)` generates four adjacent-hue anchors and `RibbonParameters` from one SplitMix64 stream. Each 5×5 point blends its corner field with two smooth diagonal-ribbon fields, then uses the current contrast corrector. CardView and CardBackView still consume only `CardVisual.colors`.

**Tech Stack:** Swift 6, SwiftUI MeshGradient, Swift Testing, XcodeGen, iPhone 17 Pro simulator.

## Global Constraints

- Preserve F72 5×5 MeshGradient, four adjacent hue anchors, F56 ranges, fixed ink, and 4.5:1 contrast.
- All computation stays in CardKit. Add no token, image, texture, layout, or passive animation.
- A seed must produce equal `CardVisual` parameters in previews and both card sides.
- Before commit run the required iPhone 17 Pro build and package suite, then full screenshot UI flow and visual inspection.

---

### Task 1: Lock F72 invariants in tests

**Files:**
- Modify: `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`

**Interfaces:**
- Consumes: `CardVisual(seed:)`, `controlPoints`, `contrastAgainstInk`.
- Produces: required `CardVisual.ribbonParameters` with Equatable fields.

- [x] **Step 1: Write the failing variation test**

Add `@Suite("CardVisual — F72 리본 변주")`. For four fixed `CardSeed.hash` values, assert reconstruction gives equal `ribbonParameters` and at least two distinct parameter sets occur:

```swift
for seed in seeds {
    #expect(CardVisual(seed: seed).ribbonParameters == CardVisual(seed: seed).ribbonParameters)
}
#expect(Set(seeds.map { CardVisual(seed: $0).ribbonParameters }).count >= 2)
```

- [x] **Step 2: Run it before implementation**

```bash
cd Packages/GyeopPackages && swift test --filter 'CardVisual — F72 리본 변주'
```

Expected: compilation fails because `ribbonParameters` is absent.

### Task 2: Generate and blend deterministic ribbon fields

**Files:**
- Modify: `Packages/GyeopPackages/Sources/CardKit/CardVisual.swift`

**Interfaces:**
- Produces: `public struct RibbonParameters: Equatable, Sendable` with two angles, widths, and offsets.
- Produces: `public let ribbonParameters: RibbonParameters`.

- [x] **Step 1: Add bounded public parameter values**

Place `RibbonParameters` in `CardVisual`. Draw its values from `rng` after the anchor generation. Make the second angle oppose the first plus a bounded deviation, giving the F72 crossing language.

- [x] **Step 2: Add continuous diagonal weighting**

Add private helpers for a signed diagonal coordinate and clamped smooth falloff from each ribbon centreline. Their widths come from `RibbonParameters`; no random call is made after initialization.

- [x] **Step 3: Blend the two fields into all 25 points**

Compute the existing four corner weights and both ribbon weights at `(u, v)`. Normalize all six weights before circular hue blending. Assign each ribbon an existing deterministic anchor color; do not generate hues outside the current adjacent sweep. Apply `colorGuaranteeingInkContrast` after the final blend.

- [x] **Step 4: Run focused coverage**

```bash
cd Packages/GyeopPackages && swift test --filter 'CardVisual'
```

Expected: determinism, variation, 5×5, range, and 100-seed contrast tests pass.

### Task 3: Verify integration and rendered cards

**Outputs:** `/tmp/Gyeop-F72.xcresult`, `/tmp/Gyeop-F72-screens`.

- [x] **Step 1: Run mandatory verification**

```bash
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
(cd Packages/GyeopPackages && swift test)
```

Expected: both exit 0.

- [x] **Step 2: Run and export the screenshot flow**

```bash
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/Gyeop-F72.xcresult -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests/testFullFlowWithScreenshots test
xcrun xcresulttool export attachments --path /tmp/Gyeop-F72.xcresult --output-path /tmp/Gyeop-F72-screens
```

Expected: test exit 0 and reveal, completed exchange, grid, detail, and back screenshots.

- [x] **Step 3: Review the card states**

Reject the change if a ribbon reads as a hard stripe, ink loses contrast, a card clips, or the received-card grid returns to one column.

### Task 4: Document and commit F72

**Files:**
- Modify: `Packages/GyeopPackages/Sources/CardKit/CardVisual.swift`
- Modify: `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift`
- Modify: `docs/card-color-guide.md`
- Modify: `docs/sprint-summary-2026-08-12.md`

- [x] **Step 1: Update the rendering docs**

Describe four anchors plus two crossing seed-defined ribbons, with the same contrast and determinism guarantees, in the color guide and sprint summary.

- [x] **Step 2: Inspect and commit after Task 3 is fresh**

```bash
git diff --check
git status --short
git add Packages/GyeopPackages/Sources/CardKit/CardVisual.swift Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift UITests/ScreenshotAndAccessibilityUITests.swift docs/card-color-guide.md docs/sprint-summary-2026-08-12.md docs/superpowers/plans/2026-08-12-f72-ribbon-wallpaper-implementation.md
git commit -m 'F72: vary card ribbons like wallpaper'
```

Expected: the commit contains only F72 renderer, tests, docs, and plan.
