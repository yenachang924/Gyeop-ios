import XCTest

final class ReleasePrivacyUITests: XCTestCase {
    @MainActor
    func testSettingsExposePrivacyAndSupportLinks() throws {
        let app = openSettings()

        XCTAssertTrue(app.links["settings.privacyPolicy"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.links["settings.privacyPolicy"].label, "개인정보처리방침")
        XCTAssertTrue(app.links["settings.support"].exists)
        XCTAssertEqual(app.links["settings.support"].label, "고객지원")
    }

    @MainActor
    func testLocalDeletionExplainsSeparateAppleAuthorizationRemoval() throws {
        let app = openSettings()
        let delete = app.buttons["settings.deleteAccount"]
        reveal(delete, in: app)
        delete.tap()
        app.alerts["계정을 삭제할까요?"].buttons["삭제"].tap()

        let completed = app.alerts["이 기기의 데이터를 삭제했어요"]
        XCTAssertTrue(completed.waitForExistence(timeout: 5))
        XCTAssertTrue(completed.buttons["Apple 연결 해제 안내"].exists)
        XCTAssertTrue(completed.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@", "Apple로 로그인"
        )).firstMatch.exists)

        completed.buttons["완료"].tap()
        XCTAssertTrue(app.buttons["onboarding.interest.연구"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["collection.myCard"].exists)
    }

    @MainActor
    private func openSettings() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-stale-profile"]
        app.launch()
        let settings = app.buttons["collection.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while (!element.exists || !element.isHittable) && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
    }
}
