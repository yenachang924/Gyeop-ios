# Current Card State Implementation Plan

> **For agentic workers:** Execute inline; the task owner prohibits subagents.

**Goal:** Make the persisted current profile drive the home card, editing flow, and 30-day refresh prompt.

**Architecture:** Keep profile freshness as a pure Core policy. `AppModel` owns persisted profile/card replacement and publishes only after both saves; SwiftUI receives immutable drafts and reuses the profile step for editing.

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Testing, XCTest.

**Spec:** `.superpowers/sdd/2026-08-21-build-5-current-card-onboarding/task-5-brief.md`

## Global Constraints

- Preserve `UserProfile.updatedAt` as an optional SwiftData field for lightweight migration compatibility.
- Use immutable replacements, 44pt actions, Dynamic Type system styles, and Reduce Motion-safe existing card behavior.
- Tests are authored before source changes; Swift and Xcode commands are NOT RUN on Windows.

### Task 1: Domain policy and persistence

**Files:** Create `Sources/Core/ProfileFreshness.swift`; modify `Persistence/UserProfileEntity.swift`; test Core and DataKit suites.

1. Add failing 29-day and 30-day boundary assertions plus a `createdAt != updatedAt` round trip assertion.
2. Add `ProfileFreshness.shouldPrompt(updatedAt:now:)` and round-trip optional `updatedAt` through entity initialization, update, and domain conversion.
3. Statically scan every entity conversion and repository call site.

### Task 2: Card and application state

**Files:** Modify `CardView.swift`, `CardKitTests.swift`, and `AppModel.swift`.

1. Add a failing card accessibility summary assertion including status, every interest, and optional MBTI.
2. Render current status as `.body` medium with a two-line limit and expose the public summary helper.
3. Load/publish `myProfile`; inject `now`; create immutable onboarding and update replacements; persist both replacement values before publishing.

### Task 3: Shared editing UI and UI coverage

**Files:** Modify profile, collection, settings, and screenshot UI test sources.

1. Add expected UI assertions for the edit control and current status, then update the supported interest selections.
2. Give `ProfileStepView` create/edit labels without duplicating validation and construct edit drafts from the current profile.
3. Present that one editor from Collection, expose freshness prompt/date, retain the home hero and exchange CTA, and add a feasible edit-to-home path.

### Task 4: Verification and handoff

1. Run static call-site, schema, immutability, and diff-whitespace checks.
2. Record unavailable Swift/Xcode test commands as NOT RUN.
3. Self-review the diff, write the requested report, and make one local conventional commit.
