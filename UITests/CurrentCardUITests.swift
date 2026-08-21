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

        let interestsNext = app.buttons["profile.edit.interests.next"]
        XCTAssertTrue(interestsNext.waitForExistence(timeout: 5))
        XCTAssertTrue(interestsNext.isEnabled)
        tapEvenIfOffscreen(app, interestsNext)

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
    func testLegacyProfileReselectsInterestsBeforeSaving() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-legacy-profile"]
        app.launch()

        let edit = app.buttons["collection.editMyCard"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()

        let interestsNext = app.buttons["profile.edit.interests.next"]
        XCTAssertTrue(interestsNext.waitForExistence(timeout: 5))
        XCTAssertFalse(interestsNext.isEnabled)

        let replacement = app.buttons["profile.edit.interest.개발"]
        tapEvenIfOffscreen(app, replacement)
        XCTAssertTrue(replacement.isSelected)
        XCTAssertTrue(interestsNext.isEnabled)
        tapEvenIfOffscreen(app, interestsNext)

        let editHeading = app.staticTexts["profile.heading"]
        XCTAssertTrue(editHeading.waitForExistence(timeout: 5))
        XCTAssertEqual(editHeading.label, "카드 수정")
        tapEvenIfOffscreen(app, app.buttons["profile.edit.save"])

        let editorDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: editHeading
        )
        XCTAssertEqual(XCTWaiter.wait(for: [editorDismissed], timeout: 5), .completed)
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
