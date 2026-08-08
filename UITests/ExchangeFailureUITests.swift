import XCTest

/// 엣지: 교환 실패 → 중립 톤 실패 화면 → "다시 맞대기" 복구 경로.
/// `-mock-exchange-fail`이 목업 교환을 timedOut으로 강제한다.
final class ExchangeFailureUITests: XCTestCase {

    @MainActor
    func testExchangeFailureShowsRetry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-mock-exchange-fail"]
        app.launch()

        // 최단 경로 온보딩
        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        firstInterest.tap()
        app.buttons["onboarding.interests.next"].tap()
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.tap()
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        app.textFields["onboarding.tagline"].tap()
        app.textFields["onboarding.tagline"].typeText("test")
        app.buttons["onboarding.emoji.클라이밍"].tap()
        app.buttons["onboarding.createCard"].tap()
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        toCollection.tap()

        // 맞대기 → 실패 화면 (timedOut) — 재시도 버튼이 복구 경로
        XCTAssertTrue(app.buttons["collection.exchange"].waitForExistence(timeout: 5))
        app.buttons["collection.exchange"].tap()
        let retry = app.buttons["exchange.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 15))

        // 재시도 → 다시 실패해도 같은 복구 경로가 유지된다
        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 15))

        // 닫기 → 컬렉션은 여전히 빈 상태 (실패는 겹을 만들지 않는다)
        app.buttons["exchange.close"].tap()
        XCTAssertTrue(app.navigationBars["컬렉션"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["collection.card.하람"].exists)
    }

    /// 디자인 QA 전 화면 인벤토리용 — 실패(중립 톤) 화면만 캡처.
    @MainActor
    func testExchangeFailureScreenshotDefault() throws {
        try captureFailureScreen(prefix: "default")
    }

    @MainActor
    func testExchangeFailureScreenshotAtMaxDynamicType() throws {
        try captureFailureScreen(
            prefix: "ax5",
            extraArgs: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        )
    }

    @MainActor
    private func captureFailureScreen(prefix: String, extraArgs: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-mock-exchange-fail"] + extraArgs
        app.launch()

        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        tapEvenIfOffscreen(app, firstInterest)
        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        tapEvenIfOffscreen(app, style)
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        app.textFields["onboarding.tagline"].tap()
        app.textFields["onboarding.tagline"].typeText("test")
        tapEvenIfOffscreen(app, app.buttons["onboarding.emoji.클라이밍"])
        tapEvenIfOffscreen(app, app.buttons["onboarding.createCard"])
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        toCollection.tap()

        XCTAssertTrue(app.buttons["collection.exchange"].waitForExistence(timeout: 5))
        app.buttons["collection.exchange"].tap()
        let retry = app.buttons["exchange.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 15))
        snap(app, "\(prefix)-11-exchange-failed")
    }

    /// Dynamic Type 극단에서는 버튼이 스크롤 밖에 있을 수 있다.
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
