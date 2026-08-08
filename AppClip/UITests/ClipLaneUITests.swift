import XCTest

/// 클립 레인 관통 UI 테스트 — `docs/navigation-map.md` §1과 1:1.
/// `_XCAppClipURL` 인보케이션 주입(디버그 환경 변수 폴백) → clip → 온보딩 3단계(본앱 뷰
/// 소스 공유) → card → bump(Mock 교환) → overlap → keep → done.
/// 핵심 검증 2가지: ① 레인이 순서대로 관통되는가 ② keep **이전** 화면 어디에도
/// 설치 유도 UI(「전체 앱 받기」)가 없는가 — 이게 제품의 핵심 주장이다.
final class ClipLaneUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"]
        app.launchEnvironment["_XCAppClipURL"] =
            "https://PLACEHOLDER.gyeop.example/clip?t=uitest-token&n=지수"
    }

    /// 관심사·이모지 카탈로그는 R3 세션이 교체 중이라 이름을 하드코딩하지 않는다 —
    /// identifier 접두사로 n번째 항목을 집는다 (본앱 뷰 소스 공유라 접두사는 안정 계약).
    private func button(withPrefix prefix: String, boundBy index: Int) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        ).element(boundBy: index)
    }

    /// 리뷰 팩용 캡처 — xcresult 첨부로 남는다 (`xcrun xcresulttool export attachments`).
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// keep 이전 화면에서 설치 유도가 절대 노출되지 않아야 한다.
    private func assertNoInstallSuggestion(stage: String) {
        XCTAssertFalse(
            app.buttons["clip.keep.install"].exists,
            "\(stage) 화면에 설치 유도 버튼이 노출됨 — keep 이전 설치 유도 금지"
        )
        XCTAssertFalse(
            app.staticTexts["전체 앱 받기"].exists,
            "\(stage) 화면에 설치 유도 문구가 노출됨"
        )
    }

    func testClipLaneTraversesToDoneAndInstallSuggestionOnlyAtKeep() {
        app.launch()

        // 1 clip — 인보케이션의 발신자 닉네임이 헤드라인에 반영된다
        let createCard = app.buttons["clip.reception.createCard"]
        XCTAssertTrue(createCard.waitForExistence(timeout: 5), "카드 수신 화면 진입 실패")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "지수님이")).firstMatch.exists)
        assertNoInstallSuggestion(stage: "clip")
        snap("clip-1-reception")

        // 설명 시트 열고 닫기 (배선표 §1-1: 닫으면 clip으로)
        app.buttons["clip.reception.how"].tap()
        let closeSheet = app.buttons["clip.reception.how.close"]
        XCTAssertTrue(closeSheet.waitForExistence(timeout: 3))
        snap("clip-1b-reception-how-sheet")
        closeSheet.tap()
        XCTAssertTrue(createCard.waitForExistence(timeout: 3))
        createCard.tap()

        // 2 interests — 본앱 뷰 재사용 (identifier가 본앱 것 그대로)
        let firstInterest = button(withPrefix: "onboarding.interest.", boundBy: 0)
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5), "온보딩 1/3(관심사) 진입 실패")

        // 뒤로 스와이프(시스템 제스처) → clip 복귀 후 재진입 (배선표 §1-2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(createCard.waitForExistence(timeout: 5), "interests 뒤로 스와이프 후 clip 복귀 실패")
        createCard.tap()
        XCTAssertTrue(firstInterest.waitForExistence(timeout: 5), "clip 복귀 후 온보딩 재진입 실패")
        firstInterest.tap()
        button(withPrefix: "onboarding.interest.", boundBy: 1).tap()
        assertNoInstallSuggestion(stage: "interests")
        snap("clip-2-interests")
        app.buttons["onboarding.interests.next"].tap()

        // 3 vibe — 4택1 선택 후 「다음」 (navigation-map §1-3)
        let style = app.buttons["onboarding.style.active-outdoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5), "온보딩 2/3(성향) 진입 실패")
        assertNoInstallSuggestion(stage: "vibe")
        snap("clip-3-vibe")
        style.tap()
        app.buttons["onboarding.style.next"].tap()

        // 4 intro — 닉네임·이모지 입력 (전부 선택사항)
        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5), "온보딩 3/3(입력) 진입 실패")
        nickname.tap()
        nickname.typeText("예나")
        button(withPrefix: "onboarding.emoji.", boundBy: 0).tap()
        assertNoInstallSuggestion(stage: "intro")
        snap("clip-4-intro")
        app.buttons["onboarding.createCard"].tap()

        // 5 card — 내 카드 + 발신자 닉네임이 맞대기 버튼에 실린다
        let bump = app.buttons["clip.card.bump"]
        XCTAssertTrue(bump.waitForExistence(timeout: 5), "card(이게 나예요) 진입 실패")
        XCTAssertEqual(bump.label, "지수님과 맞대기")
        assertNoInstallSuggestion(stage: "card")
        snap("clip-5-card")
        bump.tap()

        // 6 bump → 7 overlap — Mock 교환 스크립트(약 3초)가 흘러 겹 결과에 도달
        snap("clip-6-bump")
        let accept = app.buttons["clip.overlap.accept"]
        XCTAssertTrue(accept.waitForExistence(timeout: 15), "교환 완료 후 overlap 진입 실패")
        assertNoInstallSuggestion(stage: "overlap")
        snap("clip-7-overlap")
        accept.tap()

        // 8 keep — 여기서만 설치 제안·「나중에 할게요」
        let later = app.buttons["clip.keep.later"]
        XCTAssertTrue(later.waitForExistence(timeout: 5), "keep(보관·전환 제안) 진입 실패")
        XCTAssertTrue(app.buttons["clip.keep.install"].exists, "keep에 「전체 앱 받기」가 없다")
        snap("clip-8-keep")
        later.tap()

        // 9 done — 나의 겹
        XCTAssertTrue(app.staticTexts["clip.done.title"].waitForExistence(timeout: 5), "done(나의 겹) 진입 실패")
        snap("clip-9-done")
    }

    func testExchangeFailureShowsRetry() {
        app.launchArguments.append("-mock-exchange-fail")
        app.launch()

        let createCard = app.buttons["clip.reception.createCard"]
        XCTAssertTrue(createCard.waitForExistence(timeout: 5))
        createCard.tap()

        let interest = button(withPrefix: "onboarding.interest.", boundBy: 0)
        XCTAssertTrue(interest.waitForExistence(timeout: 5))
        interest.tap()
        app.buttons["onboarding.interests.next"].tap()

        let style = app.buttons["onboarding.style.calm-indoor"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.tap()
        app.buttons["onboarding.style.next"].tap()

        let nickname = app.textFields["onboarding.nickname"]
        XCTAssertTrue(nickname.waitForExistence(timeout: 5))
        nickname.tap()
        nickname.typeText("예나")
        button(withPrefix: "onboarding.emoji.", boundBy: 0).tap()
        app.buttons["onboarding.createCard"].tap()

        let bump = app.buttons["clip.card.bump"]
        XCTAssertTrue(bump.waitForExistence(timeout: 5))
        bump.tap()

        // 실패 → 재시도 버튼 (실패 화면에도 설치 유도는 없다)
        let retry = app.buttons["clip.failure.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 15), "교환 실패 화면 진입 실패")
        assertNoInstallSuggestion(stage: "failed")
        snap("clip-10-failure")
    }
}
