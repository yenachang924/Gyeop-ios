# Submission Readiness and TestFlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove placeholder-domain release risk, prepare review material, and upload build 2 to TestFlight.

**Architecture:** The first submission contains Gyeop only. `GyeopClip` stays defined for future domain-backed work but Gyeop does not embed it. The main entitlement retains Apple sign-in and App Group only. Documentation separates completed repository work from owner actions.

**Tech Stack:** XcodeGen, Xcode build/archive, Swift Package Manager, XCTest UI tests, App Store Connect upload.

## Global Constraints

- Work only in the `bocaccio` worktree on `design-gyeop-visual-update`.
- Exclude App Clip from the first submission under the existing decision; do not add an F-number.
- Do not alter DesignSystem, WelcomeView, navigation, or security architecture.
- Regenerate the project with `xcodegen generate`; do not edit `project.pbxproj`.
- Use iPhone 17 Pro (iOS 26.5) and run app build plus package tests before committing.

---

### Task 1: Release configuration and build number

**Files:**
- Modify: `App/Support/Gyeop.entitlements`
- Modify: `project.yml`
- Generated: `App/Support/Info.plist`
- Generated: `Gyeop.xcodeproj/project.pbxproj`

**Produces:** Main app without associated domains or embedded App Clip, version `1.0 (2)`.

- [ ] **Step 1: Record pre-change values**

```bash
plutil -p App/Support/Gyeop.entitlements
rg -n -C 2 'target: GyeopClip' project.yml
plutil -extract CFBundleVersion raw App/Support/Info.plist
```

Expected: two placeholder domains, an embedded Clip dependency, and build `1`.

- [ ] **Step 2: Apply only the required edits**

Delete the complete `com.apple.developer.associated-domains` key from the main entitlement. Delete only `- target: GyeopClip` from `Gyeop.dependencies` in `project.yml`. Add `CFBundleShortVersionString: "1.0"` and `CFBundleVersion: "2"` under Gyeop's generated `info.properties`, then regenerate the Info.plist.
Set `DEVELOPMENT_TEAM: M63YMWAA5V` in base settings, using the team ID already recorded in `site/README.md`.

- [ ] **Step 3: Regenerate and verify target composition**

```bash
xcodegen generate
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
plutil -p App/Support/Gyeop.entitlements
```

Expected: exit 0, no associated-domains key, and no Gyeop-to-GyeopClip build edge.

### Task 2: Reviewer and owner handoff documentation

**Files:**
- Modify: `docs/submission-checklist.md`
- Modify: `docs/review-kit.md`

**Produces:** Actionable external handoffs and a reviewer note covering private exchange and Mock simulation.

- [ ] **Step 1: Update checklist status**

Replace the video checkbox with owner-ready wording that cites `review-kit.md` §2. Mark main-app placeholder removal complete. Mark App Clip registration deferred from this first submission pending a production domain and AASA. Retain app-record creation, screenshot upload, privacy-policy publication, review-note/video URL insertion, and TestFlight delivery as external actions with their prerequisites.

- [ ] **Step 2: Replace the review-note draft**

Keep Apple sign-in and account deletion instructions. State that exchange is local, private, and one-to-one between nearby devices with no public profile, feed, or search. Add the single-device route: finish onboarding, open `나의 카드`, tap `카드 맞대기`, and use the simulator Mock exchange to reach overlap and received-card states. Preserve the video URL as owner-only insertion text.

- [ ] **Step 3: Check consistency**

```bash
rg -n 'PLACEHOLDER.gyeop.example|실도메인 교체 후 재빌드|🔲' docs/submission-checklist.md docs/review-kit.md
git diff --check
```

Expected: no placeholder replacement is requested for the first main-app release, and no unqualified `🔲` item remains.

### Task 3: Release verification and archive

**Outputs outside repository:** `/tmp/Gyeop-TestFlight.xcresult`, `/tmp/Gyeop-TestFlight-screens`, `/tmp/Gyeop.xcarchive`.

- [ ] **Step 1: Run required code verification**

```bash
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
(cd Packages/GyeopPackages && swift test)
```

Expected: both commands exit 0.

- [ ] **Step 2: Verify the screenshot flow**

```bash
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/Gyeop-TestFlight.xcresult -only-testing:GyeopUITests/ScreenshotAndAccessibilityUITests/testFullFlowWithScreenshots test
rm -rf /tmp/Gyeop-TestFlight-screens
xcrun xcresulttool export attachments --path /tmp/Gyeop-TestFlight.xcresult --output-path /tmp/Gyeop-TestFlight-screens
```

Expected: test exit 0 and exported image attachments for visual review.

- [ ] **Step 3: Archive the app-only scheme**

```bash
xcodebuild -project Gyeop.xcodeproj -scheme Gyeop -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/Gyeop.xcarchive archive
```

Expected: exit 0 and archive metadata for `com.gyeop.app`, version `1.0`, build `2`, with no App Clip product.

### Task 4: TestFlight delivery

**Consumes:** Task 3 archive plus an Apple Distribution identity and App Store Connect authentication.

**Produces:** Accepted build `1.0 (2)`, or a precise prerequisite report.

- [ ] **Step 1: Check release credentials without disclosing them**

```bash
security find-identity -v -p codesigning
xcrun altool --help
```

Expected: an Apple Distribution identity and a supported authentication route.

- [ ] **Step 2: Upload after credentials are available**

Use Xcode Organizer’s Distribute App workflow for `/tmp/Gyeop.xcarchive`, selecting App Store Connect > Upload, or the owner's approved `altool` credential flow. Never print API keys, app-specific passwords, or tokens.

- [ ] **Step 3: Record the delivery state**

After accepted upload, mark the archive/TestFlight checklist item complete and record build `2`. If authentication or distribution signing is unavailable, leave it external and report the exact missing prerequisite without modifying signing settings.

### Task 5: Commit repository work

**Files:** Task 1 and Task 2 files, plus generated project file.

- [ ] **Step 1: Inspect the final change set**

```bash
git diff --check
git status --short
git diff -- App/Support/Gyeop.entitlements project.yml App/Support/Info.plist docs/submission-checklist.md docs/review-kit.md
```

Expected: only planned release configuration, build number, generated project, and documentation edits.

- [ ] **Step 2: Commit after fresh Task 3 verification**

```bash
git add App/Support/Gyeop.entitlements project.yml App/Support/Info.plist Gyeop.xcodeproj/project.pbxproj docs/submission-checklist.md docs/review-kit.md
git commit -m 'chore: prepare first TestFlight build'
```

Expected: a clean worktree except archive and test files in `/tmp`.
