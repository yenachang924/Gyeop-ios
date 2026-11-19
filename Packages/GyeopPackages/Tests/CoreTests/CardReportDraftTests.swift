import Foundation
import Testing
@testable import Core

@Suite("User-composed card report")
struct CardReportDraftTests {
    @Test("신고 사유와 표시된 카드 정보만 이메일 초안에 넣는다")
    func buildsVisibleDraftWithoutSending() throws {
        let card = MockData.sampleCards[0]
        let draft = try CardReportDraft(card: card, reason: "원치 않는 모욕적인 내용을 받았어요")
        let components = try #require(URLComponents(url: draft.mailtoURL, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "mailto")
        #expect(components.path == "yenachang924@gmail.com")
        #expect(draft.body.contains(card.ownerID))
        #expect(draft.body.contains(card.nickname))
        #expect(draft.body.contains("원치 않는 모욕적인 내용을 받았어요"))
    }

    @Test("사유 안의 URI 문자가 수신자나 숨은 참조를 추가하지 않는다")
    func encodesReasonWithoutHeaderInjection() throws {
        let reason = "내용 &bcc=other@example.com#fragment"
        let draft = try CardReportDraft(card: MockData.sampleCards[0], reason: reason)
        let components = try #require(URLComponents(url: draft.mailtoURL, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.count == 2)
        #expect(components.queryItems?.first(where: { $0.name == "bcc" }) == nil)
        #expect(components.queryItems?.first(where: { $0.name == "body" })?.value == draft.body)
    }

    @Test("빈 사유와 길이 초과는 초안을 만들지 않는다")
    func rejectsInvalidReason() {
        #expect(throws: CardReportDraft.Error.emptyReason) {
            try CardReportDraft(card: MockData.sampleCards[0], reason: " \n ")
        }
        #expect(throws: CardReportDraft.Error.reasonTooLong) {
            try CardReportDraft(card: MockData.sampleCards[0], reason: String(repeating: "a", count: 1_001))
        }
    }
}
