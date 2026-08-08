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
        tagline.typeText("test user")

        app.buttons["onboarding.emoji.클라이밍"].tap()

        let create = app.buttons["onboarding.createCard"]
        create.tap()

        // 카드 리빌 → 컬렉션
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        toCollection.tap()

        // 컬렉션 도착 (첫 진입은 빈 상태 — 데모 시딩 제거됨)
        XCTAssertTrue(app.navigationBars["컬렉션"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["collection.myCard"].waitForExistence(timeout: 5))

        // 맞대기 — 시뮬레이터는 MockExchangeSession 스크립트가 겹을 성립시킨다
        app.buttons["collection.exchange"].tap()
        let exchangeDone = app.buttons["exchange.done"]
        XCTAssertTrue(exchangeDone.waitForExistence(timeout: 15))
        exchangeDone.tap()

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

    /// 완료 기준 검증: 관심사·성향·닉네임·한 줄·이모지를 전부 비워도 카드 완성까지
    /// 진행되고(전부 선택사항화), 이모지 그리드는 검색으로 1차 16개 밖의 항목도 찾을 수 있다.
    @MainActor
    func testProfileFieldsAreOptionalAndEmojiSearchFindsBeyondFirst16() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // 1/3 관심사 — 1개만 선택하고 다음 (프리뷰가 물드는지는 접근성 식별자로 확인)
        let firstInterest = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        firstInterest.tap()
        let filledPreview = app.descendants(matching: .any)["onboarding.interests.preview.filled"]
        XCTAssertTrue(filledPreview.waitForExistence(timeout: 5))
        app.buttons["onboarding.interests.next"].tap()

        // 2/3 성향
        let style = app.buttons["onboarding.style.active-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.tap()

        // 3/3 — 1차 16개 밖(카탈로그 17번째 행)인 "낚시"는 기본 그리드엔 없다가 검색하면 나타난다
        let searchField = app.textFields["onboarding.emoji.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.emoji.낚시"].exists)
        searchField.tap()
        searchField.typeText("낚시")
        XCTAssertTrue(app.buttons["onboarding.emoji.낚시"].waitForExistence(timeout: 5))

        // 닉네임·한 줄·이모지 전부 비운 채로 바로 카드 완성 — 버튼이 활성 상태여야 한다
        let create = app.buttons["onboarding.createCard"]
        XCTAssertTrue(create.isEnabled)
        create.tap()

        XCTAssertTrue(app.buttons["reveal.toCollection"].waitForExistence(timeout: 5))
    }
}
