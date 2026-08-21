# Task 2 Report — Immutable Profile Input Validation

## Status

Implemented the Build 5 immutable profile-input boundary at commit time.

## Files

- `Packages/GyeopPackages/Sources/Core/Models/ProfileInput.swift` — immutable normalized input and typed validation errors.
- `Packages/GyeopPackages/Sources/Core/Models/UserProfile.swift` — immutable fields, `updatedAt`, timestamp fallback, and status alias.
- `Packages/GyeopPackages/Sources/Core/Models/CardSnapshot.swift` — status alias while retaining `tagline`.
- `Packages/GyeopPackages/Tests/CoreTests/ProfileInputTests.swift` — validation, normalization, aliases, and legacy-decoding behavior.
- `Packages/GyeopPackages/Tests/CoreTests/CoreTests.swift` — replaces the existing mutable profile fixture with a replacement value.
- `Packages/GyeopPackages/Tests/CardKitTests/CardKitTests.swift` and `Packages/GyeopPackages/Tests/GyeopKitTests/CardPayloadTests.swift` — replace existing mutable test fixtures required to compile against immutable `UserProfile`.

## Static verification

- `git diff --check` completed with exit code 0 (only line-ending warnings).
- Inspected all `UserProfile` call sites; the new optional `updatedAt` default preserves current source call sites.
- Inspected synthesized Codable compatibility: an absent optional `updatedAt` decodes as `nil`; behavioral coverage verifies `lastUpdatedAt == createdAt` for a legacy payload.
- Confirmed `UserProfile` has no mutable stored profile fields; `currentStatus` and `lastUpdatedAt` are read-only computed properties.

## Mutation check

- Removing trimming fails normalization and duplicate-after-trimming tests.
- Removing empty checks, emoji validation, count validation, trimmed-empty-interest validation, duplicate validation, or the 40-character boundary fails a focused validation test.
- Removing the `updatedAt ?? createdAt` fallback fails legacy decoding coverage; replacing immutable fields with mutation would require reverting the replacement-value fixtures.

## Deferred RED/GREEN commands (NOT RUN — Swift unavailable on this Windows host)

```powershell
swift test --package-path Packages/GyeopPackages --filter ProfileInputTests
swift test --package-path Packages/GyeopPackages --filter CoreTests
```

## Concerns

Swift compilation and test execution must be performed on macOS. Existing CardKit and GyeopKit test fixtures mutated `UserProfile`; they were changed to construct replacement values so the immutable model compiles across package tests.
