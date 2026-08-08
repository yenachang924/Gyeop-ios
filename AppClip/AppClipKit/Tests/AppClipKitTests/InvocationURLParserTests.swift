import Foundation
import Testing
@testable import AppClipKit

@Suite("InvocationURLParser")
struct InvocationURLParserTests {
    @Test("https 유니버설 링크에서 토큰·닉네임을 읽는다")
    func parsesUniversalLink() throws {
        let url = URL(string: "https://clip.gyeop.example/c?t=abc123&n=%EC%A7%80%ED%98%B8")!
        let invocation = try InvocationURLParser.parse(url)
        #expect(invocation.exchangeToken == "abc123")
        #expect(invocation.inviterNickname == "지호")
    }

    @Test("gyeop:// 커스텀 스킴(QR 폴백)도 같은 쿼리 스키마로 파싱된다")
    func parsesCustomSchemeFallback() throws {
        let url = URL(string: "gyeop://clip?t=xyz789")!
        let invocation = try InvocationURLParser.parse(url)
        #expect(invocation.exchangeToken == "xyz789")
        #expect(invocation.inviterNickname == nil)
    }

    @Test("빈 닉네임 쿼리는 nil로 취급한다")
    func emptyNicknameBecomesNil() throws {
        let url = URL(string: "https://clip.gyeop.example/c?t=abc123&n=")!
        let invocation = try InvocationURLParser.parse(url)
        #expect(invocation.inviterNickname == nil)
    }

    @Test("토큰이 없으면 missingToken을 던진다")
    func throwsWhenTokenMissing() {
        let url = URL(string: "https://clip.gyeop.example/c?n=지호")!
        #expect(throws: InvocationParsingError.missingToken) {
            try InvocationURLParser.parse(url)
        }
    }

    @Test("지원하지 않는 스킴은 unsupportedScheme을 던진다")
    func throwsOnUnsupportedScheme() {
        let url = URL(string: "mailto:foo@example.com")!
        #expect(throws: InvocationParsingError.unsupportedScheme) {
            try InvocationURLParser.parse(url)
        }
    }
}
