import XCTest

final class ReleaseSafetyUITests: XCTestCase {
    @MainActor
    func testBlockedOwnerCannotReturnThroughMockExchangeSuccess() throws {
        let app = makeCollection()
        exchange(app)
        app.buttons["exchange.done"].tap()
        let received = app.buttons["collection.card.하람"]
        reveal(received, in: app)
        received.tap()
        app.buttons["cardDetail.safety"].tap()
        app.buttons["사용자 차단"].tap()
        app.alerts["이 사용자를 차단할까요?"].buttons["차단"].tap()
        XCTAssertTrue(app.buttons["collection.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(received.exists)

        app.buttons["collection.exchange"].tap()
        XCTAssertTrue(app.buttons["exchange.retry"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["겹이 쌓였어요"].exists)
    }

    @MainActor
    private func makeCollection() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        let first = app.buttons["onboarding.interest.연구"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        app.buttons["onboarding.interest.글쓰기"].tap()
        app.buttons["onboarding.interest.디자인"].tap()
        app.buttons["onboarding.interests.next"].tap()
        let skip = app.buttons["onboarding.mbti.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        for (field, value) in [("onboarding.nickname", "예나"), ("onboarding.currentStatus", "앱을 만들고 있어요"), ("onboarding.emoji", "🌱")] {
            let input = app.textFields[field]
            reveal(input, in: app)
            input.tap()
            input.typeText(value)
        }
        app.buttons["onboarding.createCard"].tap()
        let collection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(collection.waitForExistence(timeout: 5))
        collection.tap()
        return app
    }

    @MainActor
    private func exchange(_ app: XCUIApplication) {
        app.buttons["collection.exchange"].tap()
        XCTAssertTrue(app.buttons["exchange.done"].waitForExistence(timeout: 15))
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while (!element.exists || !element.isHittable) && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }
}
