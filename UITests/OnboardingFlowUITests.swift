import XCTest

/// 완료 기준 검증: 온보딩 3단계 → (목업) 카드 리빌 → 컬렉션 클릭 관통.
/// 매 실행이 첫 실행이 되도록 앱 데이터를 초기화하고 시작한다.
final class OnboardingFlowUITests: XCTestCase {

    @MainActor
    func testBuild5RequiresThreeInterestsAndCurrentStatus() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        let next = app.buttons["onboarding.interests.next"]
        app.buttons["onboarding.interest.AI"].tap()
        app.buttons["onboarding.interest.UX/UI"].tap()
        XCTAssertFalse(next.isEnabled)
        app.buttons["onboarding.interest.개발"].tap()
        XCTAssertTrue(next.isEnabled)
        next.tap()

        app.buttons["onboarding.mbti.skip"].tap()
        app.textFields["onboarding.nickname"].tap()
        app.textFields["onboarding.nickname"].typeText("예나")
        app.textFields["onboarding.currentStatus"].tap()
        app.textFields["onboarding.currentStatus"].typeText("첫 iOS 앱을 만들고 있어요")
        app.textFields["onboarding.emoji"].tap()
        app.textFields["onboarding.emoji"].typeText("🌱")

        XCTAssertTrue(app.buttons["onboarding.createCard"].isEnabled)
    }

    /// 완료 기준 검증: 닉네임·지금의 나·이모지가 **전부 필수**(F28)라 하나라도 비면 카드 완성이
    /// 비활성이다. 이모지는 시스템 키보드 필드 하나이고, 이모지가 아닌 글자는 버려진다 (F63).
    @MainActor
    func testProfileFieldsAreAllRequiredAndEmojiFieldFiltersInput() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        // 1/3 관심사 — 1개 선택하면 프리뷰가 물든다.
        let firstInterest = app.buttons["onboarding.interest.AI"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        firstInterest.tap()
        let filledPreview = app.descendants(matching: .any)["onboarding.interests.preview.filled"]
        XCTAssertTrue(filledPreview.waitForExistence(timeout: 5))
        app.buttons["onboarding.interest.UX/UI"].tap()
        app.buttons["onboarding.interest.개발"].tap()
        app.buttons["onboarding.interests.next"].tap()

        // 2/3 성향 — 건너뛰기는 항상 가능하다.
        XCTAssertTrue(app.buttons["onboarding.mbti.skip"].waitForExistence(timeout: 5))
        app.buttons["onboarding.mbti.skip"].tap()

        // 3/3 — 이모지 칸은 필드 하나 (F63, 카테고리 그리드 은퇴)
        let emojiField = app.textFields["onboarding.emoji"]
        XCTAssertTrue(emojiField.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.emoji.category.추천"].exists, "카테고리 칩이 남아 있음")

        // 아무것도 안 채우면 카드 완성은 비활성 (F28 — 셋 다 필수)
        let create = app.buttons["onboarding.createCard"]
        XCTAssertFalse(create.isEnabled)

        // 닉네임만 채워도 아직 비활성
        let nickname = app.textFields["onboarding.nickname"]
        nickname.tap()
        nickname.typeText("yena")
        XCTAssertFalse(create.isEnabled, "지금의 나·이모지가 비었는데 카드 완성이 활성화됨")

        // 지금의 나까지 채워도 이모지가 없으면 비활성
        let currentStatus = app.textFields["onboarding.currentStatus"]
        currentStatus.tap()
        currentStatus.typeText("첫 iOS 앱을 만들고 있어요")
        XCTAssertFalse(create.isEnabled, "이모지가 비었는데 카드 완성이 활성화됨")

        // 이모지까지 담으면 활성. 이모지가 아닌 글자는 버려진다 (F63)
        emojiField.tap()
        emojiField.typeText("a")
        XCTAssertFalse(create.isEnabled, "이모지가 아닌 글자가 담김")
        emojiField.typeText("🧗")
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
    private func completeOnboarding(_ app: XCUIApplication) {
        let interests = ["AI", "UX/UI", "개발"]
        let first = app.buttons["onboarding.interest.\(interests[0])"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        for name in interests {
            app.buttons["onboarding.interest.\(name)"].tap()
        }
        app.buttons["onboarding.interests.next"].tap()

        let skip = app.buttons["onboarding.mbti.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        let currentStatus = app.textFields["onboarding.currentStatus"]
        currentStatus.tap()
        currentStatus.typeText("첫 iOS 앱을 만들고 있어요")
        app.textFields["onboarding.emoji"].tap()
        app.textFields["onboarding.emoji"].typeText("🧗")

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

        completeOnboarding(app)

        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        hold(3.0) // 카드 등장 스프링 + 카드 감상
        toCollection.tap()
        XCTAssertTrue(app.buttons["collection.myCard"].waitForExistence(timeout: 5))
        hold(2.0)
    }

    /// 장면 2 — 겹! 순간: 융합(goo) → 링 파동 1회 → "겹!" → 겹친 칩 순차 페이드인.
    /// (F66에서 긴 이름이 선택지에서 빠져 Mock 상대(하람)와의 겹침은 데모에서 재현되지 않는다 —
    /// 겹침 0개 변형이 대신 보인다.)
    @MainActor
    func testScene2_GyeopMoment() throws {
        try guardDemo()
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()

        completeOnboarding(app)

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
        let first = app.buttons["onboarding.interest.AI"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        hold(1.2)
        // LazyVGrid는 화면 밖 요소를 만들지 않는다 — 첫 화면에 보이는 칩만 쓴다
        app.buttons["onboarding.interest.UX/UI"].tap()
        hold(1.2)
        app.buttons["onboarding.interest.AI"].tap()
        hold(1.2)
        app.buttons["onboarding.interest.AI"].tap() // 해제 — 색이 다시 물든다
        hold(1.2)
        app.buttons["onboarding.interest.개발"].tap()
        app.buttons["onboarding.interests.next"].tap()

        let skip = app.buttons["onboarding.mbti.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        hold(1.0)
        skip.tap()

        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("yena")
        let currentStatus = app.textFields["onboarding.currentStatus"]
        currentStatus.tap()
        currentStatus.typeText("첫 iOS 앱을 만들고 있어요")

        let emojiField = app.textFields["onboarding.emoji"]
        XCTAssertTrue(emojiField.waitForExistence(timeout: 5))
        emojiField.tap()
        emojiField.typeText("🧗")
        hold(1.0)
        app.buttons["onboarding.createCard"].tap()

        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        hold(1.5)
        toCollection.tap()

        // 홈 카드 플립 (F61) — 탭하면 뒷면(MBTI·관심사), 다시 탭하면 앞면
        let myCard = app.buttons["collection.myCard"]
        XCTAssertTrue(myCard.waitForExistence(timeout: 5))
        hold(1.0)
        myCard.tap()
        hold(1.5)
        myCard.tap()
        hold(1.5)
    }
}
