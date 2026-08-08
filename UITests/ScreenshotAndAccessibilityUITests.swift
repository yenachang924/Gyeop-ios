import XCTest

/// 심사 스크린샷 캡처(전체 플로우) + Dynamic Type 극단(XS/AX5)에서 플로우가
/// 깨지지 않는지 검증. 캡처는 xcresult 첨부로 남는다 —
/// `xcrun xcresulttool export attachments`로 추출 (docs/review-kit.md).
final class ScreenshotAndAccessibilityUITests: XCTestCase {

    @MainActor
    func testFullFlowWithScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        try runFullFlow(app, prefix: "default")
    }

    /// 로그인 게이트(SIWA) — 디자인 QA 전 화면 인벤토리용. `-uitest-reset` 없이 launch해
    /// (프레시 설치 = 토큰 없음) Welcome이 실제로 뜨는 경로를 그대로 캡처한다.
    @MainActor
    func testWelcomeScreenDefault() throws {
        let app = XCUIApplication()
        app.launch()
        let signIn = app.buttons["welcome.signInWithApple"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        snap(app, "default-0-welcome")
    }

    @MainActor
    func testWelcomeScreenAtMaxDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        let signIn = app.buttons["welcome.signInWithApple"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        snap(app, "ax5-0-welcome")
    }

    /// 선택 상태 보조 컷 — 풀 플로우 인벤토리는 화면 진입 직후(선택 전)만 담기므로,
    /// 칩·성향 셀의 "선택됨" 시각 상태를 기록하는 전용 캡처. (U1: 선택은 무채 잉크 채움)
    @MainActor
    func testSelectionStatesCapture() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        // 그리드 상단 두 칩 — 스크롤 없이 선택 상태가 프레임에 남는다
        let first = app.buttons["onboarding.interest.달리기"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        app.buttons["onboarding.interest.클라이밍"].tap()
        snap(app, "default-1b-interests-selected")

        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        tapEvenIfOffscreen(app, style)
        snap(app, "default-2b-style-selected")
    }

    /// Dynamic Type 최대(AX5) — 레이아웃이 깨져 버튼이 사라지면 여기서 실패한다.
    @MainActor
    func testFullFlowAtMaxDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uitest-reset",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        try runFullFlow(app, prefix: "ax5")
    }

    /// Dynamic Type 최소(XS)
    @MainActor
    func testFullFlowAtMinDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uitest-reset",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXS",
        ]
        app.launch()
        try runFullFlow(app, prefix: "xs")
    }

    /// 다크 모드 전 화면 (U3 디테일 패스) — POSTECH Red 액센트·overlap 3값·글라스가
    /// 다크에서도 대비를 유지하는지 실화면으로 확인.
    ///
    /// 주의: `-UIUserInterfaceStyle Dark` 런치 인자는 최신 iOS 시뮬레이터에서 더 이상
    /// 앱 외관을 바꾸지 않는다(no-op로 확인됨) — 실행 전 시뮬레이터 자체를 다크로 바꿔야 한다:
    /// `xcrun simctl ui <device-udid> appearance dark` (테스트 후 `appearance light`로 복구).
    @MainActor
    func testFullFlowDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        try runFullFlow(app, prefix: "dark")
    }

    @MainActor
    private func runFullFlow(_ app: XCUIApplication, prefix: String) throws {
        // 1/3 관심사
        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-1-onboarding-interests")
        firstInterest.tap()
        // AX5에서는 LazyVGrid가 화면 밖 칩을 아직 안 만들었을 수 있다 — 스크롤해서 탭
        tapEvenIfOffscreen(app, app.buttons["onboarding.interest.보드게임"])
        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])

        // 2/3 성향 — 4택1 선택 후 「다음」
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-2-onboarding-style")
        tapEvenIfOffscreen(app, style)
        tapEvenIfOffscreen(app, app.buttons["onboarding.style.next"])

        // 3/3 프로필
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        app.textFields["onboarding.tagline"].tap()
        app.textFields["onboarding.tagline"].typeText("보드게임 좋아하는 사람")
        tapEvenIfOffscreen(app, app.buttons["onboarding.emoji.클라이밍"])
        snap(app, "\(prefix)-3-onboarding-profile")
        tapEvenIfOffscreen(app, app.buttons["onboarding.createCard"])

        // 카드 리빌
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-4-card-reveal")
        toCollection.tap()

        // 컬렉션 (빈 상태)
        XCTAssertTrue(app.navigationBars["컬렉션"].waitForExistence(timeout: 5))
        snap(app, "\(prefix)-5-collection-empty")

        // 맞대기 — 탐색 중 → 겹 성립
        app.buttons["collection.exchange"].tap()
        snap(app, "\(prefix)-6-exchange-searching")
        let exchangeDone = app.buttons["exchange.done"]
        XCTAssertTrue(exchangeDone.waitForExistence(timeout: 15))
        snap(app, "\(prefix)-7-exchange-completed")
        exchangeDone.tap()

        // 컬렉션 — 받은 카드
        let received = app.buttons["collection.card.하람"]
        var swipes = 0
        while !received.exists && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(received.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-8-collection-filled")

        // 카드 상세
        received.tap()
        let close = app.buttons["닫기"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-9-card-detail")
        close.tap()

        // 설정 (계정 삭제 노출 확인 — 심사 5.1.1(v))
        if swipes > 0 { app.swipeDown() }
        app.buttons["collection.settings"].tap()
        let deleteButton = app.buttons["settings.deleteAccount"]
        var settingsSwipes = 0
        while !deleteButton.exists && settingsSwipes < 5 {
            app.swipeUp()
            settingsSwipes += 1
        }
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-10-settings")
    }

    /// Dynamic Type 극단에서는 버튼이 스크롤 밖에 있을 수 있다 — 화면에 들어올 때까지 스크롤.
    @MainActor
    private func tapEvenIfOffscreen(_ app: XCUIApplication, _ element: XCUIElement) {
        var swipes = 0
        while (!element.exists || !element.isHittable) && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) not reachable")
        element.tap()
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
