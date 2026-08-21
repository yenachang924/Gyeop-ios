import XCTest

final class CurrentCardUITests: XCTestCase {

    @MainActor
    func testSavingStaleProfileDismissesRefreshPrompt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-stale-profile"]
        app.launch()

        let refreshPrompt = app.buttons["요즘의 내가 달라졌나요?"]
        XCTAssertTrue(refreshPrompt.waitForExistence(timeout: 5))
        XCTAssertEqual(refreshPrompt.label, "요즘의 내가 달라졌나요?")

        refreshPrompt.tap()

        let editHeading = app.staticTexts["profile.heading"]
        XCTAssertTrue(editHeading.waitForExistence(timeout: 5))
        XCTAssertEqual(editHeading.label, "카드 수정")

        let save = app.buttons["profile.edit.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        tapEvenIfOffscreen(app, save)

        let editorDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: editHeading
        )
        XCTAssertEqual(XCTWaiter.wait(for: [editorDismissed], timeout: 5), .completed)
        XCTAssertFalse(refreshPrompt.exists)
        XCTAssertTrue(app.buttons["collection.editMyCard"].waitForExistence(timeout: 5))
    }

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
}
