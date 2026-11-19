import Core
import Foundation
import Testing
@testable import GyeopKit

@Suite("CardPayload — 직렬화")
struct CardPayloadTests {
    @Test("JSON 구조가 맞아도 부적절한 카드 내용은 수신하지 않는다")
    func rejectsObjectionableCardPayload() throws {
        let original = MockData.sampleCards[0]
        let card = CardSnapshot(
            ownerID: original.ownerID, seed: original.seed, nickname: "씨발",
            tagline: original.tagline, emoji: original.emoji, interests: original.interests,
            mbti: original.mbti, version: original.version, createdAt: original.createdAt
        )
        let data = try JSONEncoder().encode(card)
        #expect(throws: CardPayloadError.objectionableContent) { try CardPayload.decode(data) }
    }

    @Test("인코딩 후 디코딩하면 원본과 같다")
    func roundTrip() throws {
        let card = MockData.sampleCards[0]
        let data = try CardPayload.encode(card)
        let decoded = try CardPayload.decode(data)
        #expect(decoded == card)
    }

    @Test("상한을 넘는 카드는 인코딩 단계에서 던진다")
    func tooLargeThrowsOnEncode() {
        let profile = MockData.sampleProfiles[0]
        let oversizedProfile = UserProfile(
            id: profile.id,
            nickname: profile.nickname,
            tagline: String(repeating: "a", count: CardPayload.maxByteCount + 1),
            emoji: profile.emoji,
            interests: profile.interests,
            mbti: profile.mbti,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
        let oversized = MockCardGenerator().makeCard(from: oversizedProfile)

        #expect(throws: CardPayloadError.self) {
            try CardPayload.encode(oversized)
        }
    }

    @Test("상한을 넘는 원시 데이터는 디코딩 단계에서 던진다")
    func tooLargeThrowsOnDecode() {
        let oversized = Data(repeating: 0, count: CardPayload.maxByteCount + 1)
        #expect(throws: CardPayloadError.self) {
            try CardPayload.decode(oversized)
        }
    }

    @Test("깨진 데이터는 decodingFailed를 던진다")
    func corruptedDataThrows() {
        let garbage = Data([0xDE, 0xAD, 0xBE, 0xEF])
        #expect(throws: CardPayloadError.decodingFailed) {
            try CardPayload.decode(garbage)
        }
    }
}
