import Foundation
import Testing
@testable import Core

@Suite("ContentModerationPolicy")
struct ContentModerationPolicyTests {
    @Test(arguments: [
        "예나", "첫 iOS 앱을 만들고 있어요", "Classical bass and Scunthorpe",
        "A passionate assistant", "시발점을 찾아 공부해요", "👨‍👩‍👧‍👦"
    ])
    func permitsOrdinaryContent(_ text: String) {
        #expect(ContentModerationPolicy.isAllowed(text: text))
    }

    @Test(arguments: [
        "fuck you", "ＦＵＣＫ", "f\u{200B}u\u{200D}c\u{2060}k", "f.u.c.k",
        "F U C K", "씨\u{200B}발", "개 새 끼", "white power", "child porn",
        "kill yourself", "\u{0000}hidden"
    ])
    func rejectsConfiguredAbuseAndObfuscation(_ text: String) {
        #expect(!ContentModerationPolicy.isAllowed(text: text))
    }

    @Test("legacy interest names and five safe interests remain receivable")
    func permitsSafeLegacyCard() {
        let card = makeCard(interests: ["개발", "AI", "해외 축구", "독서", "여행"])
        #expect(ContentModerationPolicy.isAllowed(card: card))
    }

    @Test("each visible card field is moderated")
    func rejectsAbusiveCardFields() {
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(nickname: "fuck")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(status: "white power")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(emoji: "fuck")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(interests: ["child porn"])))
    }

    @Test("malformed visible card fields do not bypass moderation")
    func rejectsMalformedCard() {
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(nickname: " \n ")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(status: "")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(emoji: "A")))
        #expect(!ContentModerationPolicy.isAllowed(card: makeCard(interests: [])))
    }

    @Test("profile creation and editing share the same moderation boundary")
    func profileInputRejectsObjectionableContent() {
        #expect(throws: ProfileInputError.objectionableContent) {
            try ProfileInput(
                nickname: "ＦＵＣＫ", currentStatus: "Building an app", emoji: "🌱",
                interests: ["연구", "글쓰기", "디자인"], mbti: nil
            )
        }
        #expect(throws: ProfileInputError.objectionableContent) {
            try ProfileInput(
                nickname: "Ana", currentStatus: "kill yourself", emoji: "🌱",
                interests: ["연구", "글쓰기", "디자인"], mbti: nil
            )
        }
    }

    private func makeCard(
        nickname: String = "Ana", status: String = "Building an app",
        emoji: String = "🌱", interests: [String] = ["연구", "글쓰기", "디자인"]
    ) -> CardSnapshot {
        CardSnapshot(
            ownerID: "user-one", seed: "seed-one", nickname: nickname, tagline: status,
            emoji: emoji, interests: interests, mbti: nil, version: 1,
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
    }
}
