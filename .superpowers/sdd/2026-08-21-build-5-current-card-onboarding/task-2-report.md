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

---

## Round 1/5 fix — Unicode emoji validation

### Status and commit

Fixed the emoji-validation finding and reverted unrelated `CoreTests.swift` label/format changes. Commit subject: `fix: validate Unicode emoji profile input`.

### Test files

- `Packages/GyeopPackages/Tests/CoreTests/ProfileInputTests.swift` now rejects bare single-grapheme text (`A`, `1`) and accepts plain emoji presentation, VS16, flag, skin-tone, ZWJ family/profession, and keycap sequences.
- `Packages/GyeopPackages/Tests/CoreTests/CoreTests.swift` retains only the replacement-value fixture required by immutable `UserProfile`.

### Deferred RED/GREEN commands (NOT RUN — Swift unavailable on Windows)

```powershell
swift test --package-path Packages/GyeopPackages --filter ProfileInputTests
swift test --package-path Packages/GyeopPackages --filter CoreTests
swift test --package-path Packages/GyeopPackages
```

### Static verification

`git diff --check` exact output and exit:

```text
warning: in the working copy of 'Packages/GyeopPackages/Sources/Core/Models/ProfileInput.swift', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'Packages/GyeopPackages/Tests/CoreTests/CoreTests.swift', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'Packages/GyeopPackages/Tests/CoreTests/ProfileInputTests.swift', LF will be replaced by CRLF the next time Git touches it
DIFF_CHECK_EXIT=0
```

Focused mutation/static scan exact output:

```text
40:    func rejectsSingleNonEmojiGraphemes(_ value: String) {
44:    @Test(arguments: ["🌱", "🛠️", "🇰🇷", "👍🏽", "👨‍👩‍👧‍👦", "👩🏽‍💻", "1️⃣"])
45:    func acceptsRepresentativeUnicodeEmojiSequences(_ emoji: String) throws {
33:        guard Self.isEmoji(emoji) else {
51:    private static func isEmoji(_ value: String) -> Bool {
55:        if isKeycapSequence(scalars) { return true }
56:        if scalars.contains(where: { $0.properties.isEmojiPresentation }) { return true }
58:        let hasEmojiVariationSelector = scalars.contains { $0.value == 0xFE0F }
60:            $0.properties.isEmoji && !isKeycapBase($0)
64:    private static func isKeycapSequence(_ scalars: [Unicode.Scalar]) -> Bool {
66:              scalars.last?.value == 0x20E3,
67:              isKeycapBase(first)
71:            || (scalars.count == 3 && scalars[1].value == 0xFE0F)
74:    private static func isKeycapBase(_ scalar: Unicode.Scalar) -> Bool {
INTEREST_MEMBERSHIP_MATCHES=0
```

The `CoreTests.swift` diff against the pre-Task-2 base contains only the immutable replacement-value fixture. Interest membership remains intentionally absent for Task 3.

### Mutation check and concerns

- Replacing `Self.isEmoji` with `String.count == 1` makes the `A` and `1` rejection cases fail.
- Removing emoji-presentation support fails plain emoji, flags, skin tones, and ZWJ examples.
- Removing VS16 handling fails `🛠️`; removing keycap structure handling fails `1️⃣` while the bare `1` case prevents broad `isEmoji` acceptance.
- Swift compilation and RED/GREEN execution remain deferred to macOS; static checks cannot prove availability or exact behavior of the host Swift Unicode property tables.
