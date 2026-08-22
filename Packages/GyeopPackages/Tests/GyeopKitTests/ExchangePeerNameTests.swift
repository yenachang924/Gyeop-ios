import Testing
@testable import GyeopKit

/// `MCPeerID(displayName:)`는 UTF-8 63바이트를 넘거나 비면 예외를 던진다 — 맞대기
/// 진입에서 앱이 죽는다. 닉네임에 길이 제한이 없으므로 여기서 반드시 막아야 한다.
@Suite("맞대기 피어 이름")
struct ExchangePeerNameTests {
    private let ownerID = "6F1C2B7A-90D4-4E11-8C3F-5A2E7D9B0C4E"

    @Test("보통 닉네임은 그대로 담고 소유자 접미사를 붙인다")
    func keepsOrdinaryNickname() {
        let name = makeExchangePeerName(nickname: "예나", ownerID: ownerID)

        #expect(name == "예나#\(ownerID.suffix(8))")
    }

    @Test("이모지로만 채운 긴 닉네임도 63바이트를 넘지 않는다")
    func clampsEmojiHeavyNicknameToByteLimit() {
        // 가족 이모지 한 글자가 25바이트 — 글자 수로 자르면 300바이트가 넘는다.
        let nickname = String(repeating: "👨‍👩‍👧‍👦", count: 30)

        let name = makeExchangePeerName(nickname: nickname, ownerID: ownerID)

        #expect(name.utf8.count <= ExchangeConstants.maximumPeerNameBytes)
        #expect(!name.isEmpty)
    }

    @Test("글자를 중간에서 쪼개지 않는다")
    func neverSplitsAGrapheme() {
        let nickname = String(repeating: "👨‍👩‍👧‍👦", count: 30)

        let name = makeExchangePeerName(nickname: nickname, ownerID: ownerID)
        let body = String(name.dropLast(String(ownerID.suffix(8)).count + 1))

        #expect(body.allSatisfy { $0 == "👨‍👩‍👧‍👦" })
    }

    @Test("긴 한글 닉네임은 읽기 좋은 길이에서 멈춘다")
    func clampsLongHangulNicknameToReadableLength() {
        let name = makeExchangePeerName(nickname: String(repeating: "가", count: 40), ownerID: ownerID)
        let body = String(name.dropLast(String(ownerID.suffix(8)).count + 1))

        #expect(body.count == ExchangeConstants.maximumPeerNicknameCharacters)
        #expect(name.utf8.count <= ExchangeConstants.maximumPeerNameBytes)
    }

    @Test("닉네임이 비어도 접미사가 남아 이름이 비지 않는다")
    func neverReturnsEmptyName() {
        let name = makeExchangePeerName(nickname: "", ownerID: ownerID)

        #expect(!name.isEmpty)
        #expect(name.utf8.count <= ExchangeConstants.maximumPeerNameBytes)
    }
}
