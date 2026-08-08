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

    @MainActor
    private func runFullFlow(_ app: XCUIApplication, prefix: String) throws {
        // 1/3 관심사
        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-1-onboarding-interests")
        firstInterest.tap()
        app.buttons["onboarding.interest.보드게임"].tap()
        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])

        // 2/3 성향
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-2-onboarding-style")
        tapEvenIfOffscreen(app, style)

        // 3/3 프로필
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        app.textFields["onboarding.tagline"].tap()
        app.textFields["onboarding.tagline"].typeText("보드게임 좋아하는 러너")
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
