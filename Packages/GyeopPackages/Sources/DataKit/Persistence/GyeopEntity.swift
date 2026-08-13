import Core
import Foundation
import SwiftData

/// 겹 기록 저장 스키마. 상대 카드는 비정규화해 저장한다 — 겹은 교환 시점의 카드
/// 스냅샷을 그대로 보존해야 한다(상대가 이후 카드를 바꿔도 이 기록은 불변).
@Model
final class GyeopEntity {
    /// 동일 상대 재맞댐을 1건으로 묶는 창(spec F2 수용 기준: 24시간 1회).
    static let dedupWindow: TimeInterval = 24 * 60 * 60

    @Attribute(.unique) var id: String
    var counterpartOwnerID: String
    var counterpartSeed: String
    var counterpartNickname: String
    var counterpartTagline: String
    var counterpartEmoji: String
    var counterpartInterests: [String]
    /// 상대 MBTI 4글자 코드 — 없으면 빈 문자열 (F55).
    var counterpartMBTIRaw: String = ""
    var counterpartVersion: Int
    var counterpartCreatedAt: Date
    var methodRaw: String
    var occurredAt: Date

    init(record: GyeopRecord) {
        id = record.id
        let card = record.counterpartCard
        counterpartOwnerID = card.ownerID
        counterpartSeed = card.seed
        counterpartNickname = card.nickname
        counterpartTagline = card.tagline
        counterpartEmoji = card.emoji
        counterpartInterests = card.interests
        counterpartMBTIRaw = card.mbti?.code ?? ""
        counterpartVersion = card.version
        counterpartCreatedAt = card.createdAt
        methodRaw = record.method.rawValue
        occurredAt = record.occurredAt
    }

    func toDomain() -> GyeopRecord {
        GyeopRecord(
            id: id,
            counterpartCard: CardSnapshot(
                ownerID: counterpartOwnerID,
                seed: counterpartSeed,
                nickname: counterpartNickname,
                tagline: counterpartTagline,
                emoji: counterpartEmoji,
                interests: counterpartInterests,
                mbti: MBTI(code: counterpartMBTIRaw),
                version: counterpartVersion,
                createdAt: counterpartCreatedAt
            ),
            method: GyeopRecord.Method(rawValue: methodRaw) ?? .mock,
            occurredAt: occurredAt
        )
    }
}
