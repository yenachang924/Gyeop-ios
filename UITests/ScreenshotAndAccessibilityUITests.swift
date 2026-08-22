import XCTest

/// 심사 스크린샷 캡처(전체 플로우) + Dynamic Type 극단(XS/AX5)에서 플로우가
/// 깨지지 않는지 검증. 캡처는 xcresult 첨부로 남는다 —
/// `xcrun xcresulttool export attachments`로 추출 (docs/review-kit.md).
final class ScreenshotAndAccessibilityUITests: XCTestCase {

    /// 화면 위아래 가장자리에서 탭이 시스템 제스처에 먹히는 폭.
    private static let edgeGuard: CGFloat = 60

    @MainActor
    func testFullFlowWithScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        try runFullFlow(app, prefix: "default")
    }

    /// 로그인 게이트(SIWA) — 디자인 QA 전 화면 인벤토리용. `-uitest-reset` 없이 launch해
    /// (프레시 설치 = 토큰 없음) Welcome이 실제로 뜨는 경로를 그대로 캡처한다.
    @MainActor
    func testWelcomeScreenDefault() throws {
        let app = XCUIApplication()
        app.launch()
        let signIn = app.buttons["welcome.signInWithApple"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        snap(app, "default-0-welcome")
    }

    @MainActor
    func testWelcomeScreenAtMaxDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        let signIn = app.buttons["welcome.signInWithApple"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        snap(app, "ax5-0-welcome")
    }

    /// 선택 상태 보조 컷 — 풀 플로우 인벤토리는 화면 진입 직후(선택 전)만 담기므로,
    /// 칩·성향 셀의 "선택됨" 시각 상태를 기록하는 전용 캡처. (U1: 선택은 무채 잉크 채움)
    @MainActor
    func testSelectionStatesCapture() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        // 그리드 상단 두 칩 — 스크롤 없이 선택 상태가 프레임에 남는다
        let first = app.buttons["onboarding.interest.연구"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        app.buttons["onboarding.interest.글쓰기"].tap()
        app.buttons["onboarding.interest.디자인"].tap()
        snap(app, "default-1b-interests-selected")

        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])
        let firstAxis = app.buttons["onboarding.mbti.E"]
        XCTAssertTrue(firstAxis.waitForExistence(timeout: 5))
        firstAxis.tap()
        app.buttons["onboarding.mbti.N"].tap()
        app.buttons["onboarding.mbti.T"].tap()
        app.buttons["onboarding.mbti.P"].tap()
        snap(app, "default-2b-style-selected")
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

    @MainActor
    func testInterestsUseFullWidthAtMaxDynamicType() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uitest-reset",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()

        // 카탈로그에서 가장 긴 두 이름 — 한 열을 꽉 채우고 줄바꿈으로 흘러야 한다
        for name in ["스포츠 관람", "사이드 프로젝트"] {
            let longChoice = app.buttons["onboarding.interest.\(name)"]
            var swipes = 0
            while (!longChoice.exists || !longChoice.isHittable) && swipes < 8 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(longChoice.waitForExistence(timeout: 5), "\(name) 칩을 찾지 못했다")
            XCTAssertTrue(longChoice.isHittable, "\(name) 칩을 탭할 수 없다")
            XCTAssertGreaterThan(longChoice.frame.width, app.frame.width * 0.7)
            // 칩이 화면 안에 온전히 들어와야 한다 — 잘리면 여기서 걸린다
            XCTAssertLessThanOrEqual(longChoice.frame.maxX, app.frame.maxX)
            snap(app, "ax5-interest-\(name)")
        }
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

    /// 다크 모드 전 화면 (U3 디테일 패스) — POSTECH Red 액센트·overlap 3값·글라스가
    /// 다크에서도 대비를 유지하는지 실화면으로 확인.
    ///
    /// 주의: `-UIUserInterfaceStyle Dark` 런치 인자는 최신 iOS 시뮬레이터에서 더 이상
    /// 앱 외관을 바꾸지 않는다(no-op로 확인됨) — 실행 전 시뮬레이터 자체를 다크로 바꿔야 한다:
    /// `xcrun simctl ui <device-udid> appearance dark` (테스트 후 `appearance light`로 복구).
    @MainActor
    func testFullFlowDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launch()
        try runFullFlow(app, prefix: "dark")
    }

    @MainActor
    private func runFullFlow(_ app: XCUIApplication, prefix: String) throws {
        // 1/3 관심사
        let firstInterest = app.buttons["onboarding.interest.연구"]
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-1-onboarding-interests")
        // AX5에서는 LazyVGrid가 화면 밖 칩을 아직 안 만들었을 수 있다 — 스크롤해서 탭
        select(app, firstInterest)
        select(app, app.buttons["onboarding.interest.글쓰기"])
        select(app, app.buttons["onboarding.interest.디자인"])
        tapEvenIfOffscreen(app, app.buttons["onboarding.interests.next"])

        // 2/3 MBTI — 네 축 선택 후 「다음」 (F55)
        let firstAxis = app.buttons["onboarding.mbti.E"]
        XCTAssertTrue(firstAxis.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-2-onboarding-mbti")
        firstAxis.tap()
        app.buttons["onboarding.mbti.N"].tap()
        app.buttons["onboarding.mbti.T"].tap()
        let pPill = app.buttons["onboarding.mbti.P"]
        tapEvenIfOffscreen(app, pPill)
        // 스크롤 감속과 겹치면 탭이 스크롤 정지로 소비될 수 있다 — 선택 상태로 확인 후 재탭
        if !pPill.isSelected { pPill.tap() }
        tapEvenIfOffscreen(app, app.buttons["onboarding.mbti.next"])

        // 3/3 프로필
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        focusTextField(app, nickname)
        nickname.typeText("yena")
        let currentStatus = app.textFields["onboarding.currentStatus"]
        focusTextField(app, currentStatus)
        currentStatus.typeText("첫 iOS 앱을 만들고 있어요")
        let emojiField = app.textFields["onboarding.emoji"]
        focusTextField(app, emojiField)
        emojiField.typeText("🧗")
        snap(app, "\(prefix)-3-onboarding-profile")
        tapEvenIfOffscreen(app, app.buttons["onboarding.createCard"])

        // 카드 리빌
        let toCollection = app.buttons["reveal.toCollection"]
        XCTAssertTrue(toCollection.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-4-card-reveal")
        toCollection.tap()

        // 컬렉션 (빈 상태)
        XCTAssertTrue(app.staticTexts["나의 카드"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["collection.editMyCard"].waitForExistence(timeout: 5))
        let myCard = app.buttons["collection.myCard"]
        XCTAssertTrue(myCard.waitForExistence(timeout: 5))
        XCTAssertTrue(myCard.label.contains("첫 iOS 앱을 만들고 있어요"))
        snap(app, "\(prefix)-5-collection-empty")

        app.buttons["collection.editMyCard"].tap()
        let editInterestsNext = app.buttons["profile.edit.interests.next"]
        XCTAssertTrue(editInterestsNext.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-5b-profile-edit-interests")
        tapEvenIfOffscreen(app, editInterestsNext)
        let editHeading = app.staticTexts["profile.heading"]
        XCTAssertTrue(editHeading.waitForExistence(timeout: 5))
        XCTAssertEqual(editHeading.label, "카드 수정")
        let editableStatus = app.textFields["onboarding.currentStatus"]
        XCTAssertTrue(editableStatus.waitForExistence(timeout: 5))
        replaceText(app, editableStatus, with: "첫 iOS 앱을 만들고 있어요 업데이트")
        tapEvenIfOffscreen(app, app.buttons["profile.edit.save"])
        let updatedCard = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "첫 iOS 앱을 만들고 있어요 업데이트"),
            object: myCard
        )
        XCTAssertEqual(XCTWaiter.wait(for: [updatedCard], timeout: 5), .completed)

        let editorDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: editHeading
        )
        XCTAssertEqual(XCTWaiter.wait(for: [editorDismissed], timeout: 5), .completed)

        // 맞대기 — 탐색 중 → 겹 성립
        let exchange = app.buttons["collection.exchange"]
        let exchangeHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: exchange
        )
        XCTAssertEqual(XCTWaiter.wait(for: [exchangeHittable], timeout: 5), .completed)
        exchange.tap()
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

        // 카드 상세 — 카드가 하단 맞대기 캡슐에 걸쳐 있으면 스크롤로 끌어올린 뒤 탭
        tapEvenIfOffscreen(app, received)
        let close = app.buttons["닫기"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        snap(app, "\(prefix)-9-card-detail")

        // 카드 플립 — 뒷면(hue 유리 + MBTI) 기록 (F54)
        let flipCard = app.descendants(matching: .any)["card.flip"].firstMatch
        if flipCard.waitForExistence(timeout: 2) {
            flipCard.tap()
            // F74: 플립 중에는 양면을 잠시 합성한다. 정지한 뒷면을 기록해야 카드 정보
            // 포스터의 실제 레이아웃을 검증할 수 있다.
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            XCTAssertFalse(
                app.descendants(matching: .any)["관심사 (interests[index])"].exists,
                "뒷면의 장식 이모지는 별도 접근성 요소가 아니어야 한다"
            )
            snap(app, "\(prefix)-9b-card-back")
        }
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

    /// SwiftUI 전환 직후에는 필드가 존재해도 첫 응답자가 되기 전일 수 있다. 포커스가
    /// 실제로 잡힌 것을 확인한 뒤에만 합성 입력을 보낸다.
    @MainActor
    private func focusTextField(_ app: XCUIApplication, _ field: XCUIElement) {
        tapEvenIfOffscreen(app, field)
        var focusTries = 0
        while (field.value(forKey: "hasKeyboardFocus") as? Bool) != true && focusTries < 4 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            // AX5에서는 필드가 화면 가장자리에 걸친 채 멈춘다 — 그 자리를 탭하면 상태바나
            // 홈 인디케이터가 먼저 먹어 포커스가 안 잡힌다. 안쪽으로 옮긴 뒤 다시 탭한다.
            if field.frame.minY < app.frame.minY + Self.edgeGuard {
                app.swipeDown()
                RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            } else if field.frame.maxY > app.frame.maxY - Self.edgeGuard {
                app.swipeUp()
                RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            }
            field.tap()
            focusTries += 1
        }
        XCTAssertEqual(field.value(forKey: "hasKeyboardFocus") as? Bool, true)
    }

    /// 관심사 칩 선택. 스크롤 감속과 겹치면 첫 탭이 스크롤 정지로 소비되므로
    /// (MBTI 알약과 같은 사정) 선택 상태를 확인하고 필요하면 다시 탭한다.
    @MainActor
    private func select(_ app: XCUIApplication, _ chip: XCUIElement) {
        var tries = 0
        while !chip.isSelected && tries < 4 {
            tapEvenIfOffscreen(app, chip)
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            tries += 1
        }
        XCTAssertTrue(chip.isSelected, "\(chip) 선택되지 않음")
    }

    /// 이미 값이 있는 필드는 탭한 자리에 캐럿이 놓인다 — 그냥 치면 글자 사이에 끼어든다.
    /// 캐럿 위치(=탭 좌표)는 Dynamic Type에 따라 달라지므로 기대지 않고, 세 번 탭으로
    /// 전체를 고른 뒤 통째로 덮어쓴다.
    @MainActor
    private func replaceText(_ app: XCUIApplication, _ field: XCUIElement, with text: String) {
        focusTextField(app, field)
        var tries = 0
        while (field.value as? String) != text && tries < 3 {
            field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            field.typeText(text)
            tries += 1
        }
        XCTAssertEqual(field.value as? String, text, "「지금의 나」 입력이 기대값과 다르다")
    }

    /// Dynamic Type 극단에서는 버튼이 스크롤 밖에 있을 수 있다 — 화면에 들어올 때까지 스크롤.
    /// AX5에서는 칩이 한 열로 길게 늘어서 목표가 현재 위치보다 **위**에 남기도 한다
    /// (LazyVGrid가 지나친 칩을 이미 내려놓은 상태). 아래로 훑어 못 찾으면 위로도 훑는다.
    @MainActor
    private func tapEvenIfOffscreen(_ app: XCUIApplication, _ element: XCUIElement) {
        var swipes = 0
        while (!element.exists || !element.isHittable) && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        var backSwipes = 0
        while (!element.exists || !element.isHittable) && backSwipes < 12 {
            app.swipeDown()
            backSwipes += 1
        }
        // 감속(또는 상단 바운스)이 남아 있으면 첫 탭이 "스크롤 정지"로 소비된다 — 멎은 뒤 탭한다
        if swipes > 0 || backSwipes > 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
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
