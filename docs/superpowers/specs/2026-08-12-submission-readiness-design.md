# Submission readiness design

## Purpose

Prepare the repository for a first App Store submission that excludes the App Clip
until a production domain and AASA file exist. Make the remaining reviewer and
owner actions explicit without changing product behavior or security architecture.

## Scope

1. Remove the unused associated-domains entitlement from the main app.
2. Refresh the submission checklist so repository-complete work, owner-owned
   external work, and App Clip deferral are distinguishable.
3. Expand the App Review note with the private, one-to-one proximity-exchange
   model and the simulator Mock route.
4. Regenerate the Xcode project and verify the app build and package tests.

## Entitlements

`App/Support/Gyeop.entitlements` will retain Sign in with Apple and the App Group.
It will no longer include `com.apple.developer.associated-domains`, because both
values are placeholders and the App Clip experience is excluded from this first
submission. No real domain is substituted.

## Documentation

The checklist will turn current `🔲` items into actionable owner handoffs. The
two-device video remains owner-recorded; the repository supplies its five-shot
script and review-note insertion point. App Clip registration remains explicitly
deferred pending a real domain and AASA. The review note will state that exchanges
are local, one-to-one, and not publicly discoverable, then give the simulator Mock
path for a single-device review.

## Non-goals

- Do not change App Clip code, `project.yml`, navigation, DesignSystem tokens, or
  security architecture.
- Do not implement SIWA scope changes or a CardDetailView delete action in this
  pass.
- Do not create a new F-number: this implements the already-recorded App Clip
  submission deferral and F65 deletion decision, with no new product decision.

## Verification

Run `xcodegen generate`, the required iPhone 17 Pro app build, and
`Packages/GyeopPackages` tests. Inspect the generated entitlement plist to verify
the associated-domains key is absent, and review the documentation diff for stale
placeholder instructions.
