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
        let firstInterest = app.buttons["onboarding.interest.AI"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        firstInterest.tap()
        app.buttons["onboarding.interest.UX/UI"].tap()
        app.buttons["onboarding.interest.개발"].tap()
        app.buttons["onboarding.interests.next"].tap()
        let firstAxis = app.buttons["onboarding.mbti.E"]
        XCTAssertTrue(firstAxis.waitForExistence(timeout: 5))
        firstAxis.tap()
        app.buttons["onboarding.mbti.N"].tap()
        app.buttons["onboarding.mbti.T"].tap()
        app.buttons["onboarding.mbti.P"].tap()
        app.buttons["onboarding.mbti.next"].tap()
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        app.textFields["onboarding.currentStatus"].tap()
        app.textFields["onboarding.currentStatus"].typeText("test")
        app.textFields["onboarding.emoji"].tap()
        app.textFields["onboarding.emoji"].typeText("🧗")
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
        XCTAssertTrue(app.staticTexts["나의 카드"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["collection.card.하람"].exists)
    }
}
