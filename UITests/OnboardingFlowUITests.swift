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

        // 2/3 성향 — 슬라이더 미조작이면 다음 비활성 (F17, navigation-map §1-3)
        let energySlider = app.sliders["onboarding.style.energy"]
        XCTAssertTrue(energySlider.waitForExistence(timeout: 5))
        let styleNext = app.buttons["onboarding.style.next"]
        XCTAssertFalse(styleNext.isEnabled, "성향 미조작인데 다음이 활성화됨")
        energySlider.adjust(toNormalizedSliderPosition: 0.8)
        app.sliders["onboarding.style.venue"].adjust(toNormalizedSliderPosition: 0.2)
        XCTAssertTrue(styleNext.isEnabled, "슬라이더 조작 후에도 다음이 비활성")
        styleNext.tap()

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

    /// 완료 기준 검증: 닉네임·한 줄·이모지가 **전부 필수**(F28)라 하나라도 비면 카드 완성이
    /// 비활성이다. 이모지 그리드는 검색으로 1차 16개 밖의 항목도 찾을 수 있다.
    @MainActor
    func testProfileFieldsAreAllRequiredAndEmojiSearchFindsBeyondFirst16() throws {
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

        // 2/3 성향 — 선택 후 「다음」
        let energySlider = app.sliders["onboarding.style.energy"]
        XCTAssertTrue(energySlider.waitForExistence(timeout: 5))
        energySlider.adjust(toNormalizedSliderPosition: 0.8)
        app.sliders["onboarding.style.venue"].adjust(toNormalizedSliderPosition: 0.2)
        app.buttons["onboarding.style.next"].tap()

        // 3/3 — 1차 16개 밖(카탈로그 17번째 행)인 "낚시"는 기본 그리드엔 없다가 검색하면 나타난다
        let searchField = app.textFields["onboarding.emoji.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.emoji.낚시"].exists)
        searchField.tap()
        searchField.typeText("낚시")
        XCTAssertTrue(app.buttons["onboarding.emoji.낚시"].waitForExistence(timeout: 5))

        // 아무것도 안 채우면 카드 완성은 비활성 (F28 — 셋 다 필수)
        let create = app.buttons["onboarding.createCard"]
        XCTAssertFalse(create.isEnabled)

        // 닉네임만 채워도 아직 비활성
        let nickname = app.textFields["onboarding.nickname"]
        nickname.tap()
        nickname.typeText("yena")
        XCTAssertFalse(create.isEnabled, "한 줄·이모지가 비었는데 카드 완성이 활성화됨")

        // 한 줄까지 채워도 이모지가 없으면 비활성
        let tagline = app.textFields["onboarding.tagline"]
        tagline.tap()
        tagline.typeText("test user")
        XCTAssertFalse(create.isEnabled, "이모지가 비었는데 카드 완성이 활성화됨")

        // 이모지까지 고르면 활성
        app.buttons["onboarding.emoji.클라이밍"].tap()
        XCTAssertTrue(create.isEnabled)
        create.tap()

        XCTAssertTrue(app.buttons["reveal.toCollection"].waitForExistence(timeout: 5))
    }
}

/// U2 데모 레코딩 드라이버 — 시그니처 모션 3장면을 화면 레코딩용으로 천천히 재생한다.
/// 일반 테스트 런에서는 스킵: `TEST_RUNNER_DEMO_RECORDING=1`을 준 xcodebuild test에서만 실행
/// (TEST_RUNNER_ 접두사는 러너 프로세스 환경으로 벗겨져 들어온다).
/// 레코딩은 병행하는 `xcrun simctl io <udid> recordVideo`가 담당한다.
final class U2DemoRecordingUITests: XCTestCase {

    private func guardDemo() throws {
        guard ProcessInfo.processInfo.environment["DEMO_RECORDING"] == "1" else {
            throw XCTSkip("데모 레코딩 전용 — TEST_RUNNER_DEMO_RECORDING=1일 때만 실행")
        }
    }

    /// 장면 감상용 정지 — 애니메이션이 끝까지 재생될 시간을 준다.
    private func hold(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// 온보딩을 최소 동작으로 통과 — 장면 1·2의 공통 준비.
    @MainActor
    private func completeOnboarding(_ app: XCUIApplication, interests: [String]) {
        let first = app.buttons["onboarding.interest.\(interests[0])"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        for name in interests {
            app.buttons["onboarding.interest.\(name)"].tap()
        }
        app.buttons["onboarding.interests.next"].tap()

        let energySlider = app.sliders["onboarding.style.energy"]
        XCTAssertTrue(energySlider.waitForExistence(timeout: 5))
        energySlider.adjust(toNormalizedSliderPosition: 0.8)
        app.sliders["onboarding.style.venue"].adjust(toNormalizedSliderPosition: 0.2)
        app.buttons["onboarding.style.next"].tap()

        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        let tagline = app.textFields["onboarding.tagline"]
        tagline.tap()
        tagline.typeText("새벽 러닝에 빠졌어요")
        app.buttons["onboarding.emoji.클라이밍"].tap()

        let create = app.buttons["onboarding.createCard"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()
    }

    /// 장면 1 — 내 카드: 리빌 스프링 스케일 인(cardAppear) + 5×5 MeshGradient 카드.
    @MainActor
    func testScene1_MyCardReveal() throws {
        try guardDemo()
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        completeOnboarding(app, interests: ["클라이밍", "보드게임", "커피"])

        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        hold(3.0) // 카드 등장 스프링 + 카드 감상
        toCollection.tap()
        XCTAssertTrue(app.buttons["collection.myCard"].waitForExistence(timeout: 5))
        hold(2.0)
    }

    /// 장면 2 — 겹! 순간: 융합(goo) → 링 파동 1회 → "겹!" → 겹친 칩 순차 페이드인.
    /// Mock 상대(하람)의 관심사와 2개 겹치도록 클라이밍·보드게임을 고른다.
    @MainActor
    func testScene2_GyeopMoment() throws {
        try guardDemo()
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        completeOnboarding(app, interests: ["클라이밍", "보드게임"])

        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        toCollection.tap()

        let exchange = app.buttons["collection.exchange"]
        XCTAssertTrue(exchange.waitForExistence(timeout: 5))
        hold(1.0)
        exchange.tap()

        // Mock 스크립트(0.6s 간격) → 융합 1.5s → 완료 화면
        let done = app.buttons["exchange.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 20))
        hold(3.0) // 칩 스태거 + 이스터에그 감상
        done.tap()
        hold(1.5)
    }

    /// 장면 3 — 온보딩 마이크로(칩 스프링·프리뷰 물들기·이모지 팝) + 컬렉션 ↔ 카드 상세 줌.
    @MainActor
    func testScene3_OnboardingMicrosAndZoom() throws {
        try guardDemo()
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // 칩을 천천히 — 자리표시 → 카드 전환, 고를 때마다 색이 물들고, 해제하면 되돌아온다
        let first = app.buttons["onboarding.interest.클라이밍"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        hold(1.2)
        // LazyVGrid는 화면 밖 요소를 만들지 않는다 — 첫 화면에 보이는 칩만 쓴다
        app.buttons["onboarding.interest.수영"].tap()
        hold(1.2)
        app.buttons["onboarding.interest.달리기"].tap()
        hold(1.2)
        app.buttons["onboarding.interest.달리기"].tap() // 해제 — 색이 다시 물든다
        hold(1.2)
        app.buttons["onboarding.interests.next"].tap()

        let energySlider = app.sliders["onboarding.style.energy"]
        XCTAssertTrue(energySlider.waitForExistence(timeout: 5))
        energySlider.adjust(toNormalizedSliderPosition: 0.8)
        app.sliders["onboarding.style.venue"].adjust(toNormalizedSliderPosition: 0.2)
        hold(1.0)
        app.buttons["onboarding.style.next"].tap()

        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        let tagline = app.textFields["onboarding.tagline"]
        tagline.tap()
        tagline.typeText("새벽 러닝에 빠졌어요")

        let emoji = app.buttons["onboarding.emoji.클라이밍"]
        XCTAssertTrue(emoji.waitForExistence(timeout: 5))
        emoji.tap()
        hold(1.0)
        app.buttons["onboarding.createCard"].tap()

        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        hold(1.5)
        toCollection.tap()

        // 컬렉션 ↔ 카드 상세 — matchedTransitionSource + zoom 전환
        let myCard = app.buttons["collection.myCard"]
        XCTAssertTrue(myCard.waitForExistence(timeout: 5))
        hold(1.0)
        myCard.tap()
        let close = app.buttons["닫기"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        hold(1.5)
        close.tap()
        hold(1.5)
    }
}
