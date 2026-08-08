import XCTest

/// 완료 기준 검증: 온보딩 3단계 → (목업) 카드 리빌 → 컬렉션 클릭 관통.
/// 매 실행이 첫 실행이 되도록 앱 데이터를 초기화하고 시작한다.
final class OnboardingFlowUITests: XCTestCase {

    @MainActor
    func testOnboardingToCollection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // 1/3 관심사 — 2개 선택 후 다음
        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        firstInterest.tap()
        app.buttons["onboarding.interest.보드게임"].tap()
        app.buttons["onboarding.interests.next"].tap()

        // 2/3 성향 — 원탭 즉시 다음 단계
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.tap()

        // 3/3 닉네임·한 줄·이모지
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")

        let tagline = app.textFields["onboarding.tagline"]
        tagline.tap()
        tagline.typeText("test runner")

        app.buttons["onboarding.emoji.클라이밍"].tap()

        let create = app.buttons["onboarding.createCard"]
        create.tap()

        // 카드 리빌 → 컬렉션
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        toCollection.tap()

        // 컬렉션 도착 + 목업 겹 카드 존재
        XCTAssertTrue(app.navigationBars["컬렉션"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["collection.myCard"].waitForExistence(timeout: 5))

        // 받은 카드 탭 → 상세 시트 → 닫기 (LazyVGrid는 화면 밖 요소를 만들지 않으므로 스크롤)
        let received = app.buttons["collection.card.하람"]
        var swipes = 0
        while !received.exists && swipes < 5 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(received.waitForExistence(timeout: 5))
        received.tap()
        let close = app.buttons["닫기"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
    }
}
