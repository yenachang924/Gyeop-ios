import Core
import Foundation

/// 맞대기 중 MCSession으로 오가는 카드 페이로드의 인코딩/디코딩.
/// 상한을 두는 이유: 신뢰 못 할 상대 기기가 보내는 데이터이니 무제한으로 받아
/// 메모리를 태우게 두지 않는다 — 카드는 텍스트 위주라 여유 있게 잡아도 충분히 작다.
enum CardPayloadError: Error, Sendable, Equatable {
    case tooLarge(byteCount: Int, limit: Int)
    case decodingFailed
}

enum CardPayload {
    /// 16KB — 관심사 5개·닉네임·한줄소개 정도의 텍스트 필드엔 넉넉한 상한.
    static let maxByteCount = 16 * 1024

    static func encode(_ card: CardSnapshot) throws -> Data {
        let data = try JSONEncoder().encode(card)
        guard data.count <= maxByteCount else {
            throw CardPayloadError.tooLarge(byteCount: data.count, limit: maxByteCount)
        }
        return data
    }

    static func decode(_ data: Data) throws -> CardSnapshot {
        guard data.count <= maxByteCount else {
            throw CardPayloadError.tooLarge(byteCount: data.count, limit: maxByteCount)
        }
        do {
            return try JSONDecoder().decode(CardSnapshot.self, from: data)
        } catch {
            throw CardPayloadError.decodingFailed
        }
    }
}
