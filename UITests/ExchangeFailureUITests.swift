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
}
