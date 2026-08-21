import Foundation

public enum ProfileInputError: Error, Equatable, Sendable {
    case emptyNickname
    case emptyCurrentStatus
    case currentStatusTooLong(maximum: Int)
    case invalidEmoji
    case interestCount(expected: Int)
    case emptyInterest
    case duplicateInterest
    case unsupportedInterest(String)
}

public struct ProfileInput: Equatable, Sendable {
    public static let interestCount = 3
    public static let maximumCurrentStatusLength = 40

    public let nickname: String
    public let currentStatus: String
    public let emoji: String
    public let interests: [String]
    public let mbti: MBTI?

    public init(nickname: String, currentStatus: String, emoji: String, interests: [String], mbti: MBTI?) throws {
        let cleanNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCurrentStatus = currentStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanInterests = interests.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard !cleanNickname.isEmpty else { throw ProfileInputError.emptyNickname }
        guard !cleanCurrentStatus.isEmpty else { throw ProfileInputError.emptyCurrentStatus }
        guard cleanCurrentStatus.count <= Self.maximumCurrentStatusLength else {
            throw ProfileInputError.currentStatusTooLong(maximum: Self.maximumCurrentStatusLength)
        }
        guard Self.isEmoji(emoji) else {
            throw ProfileInputError.invalidEmoji
        }
        guard cleanInterests.count == Self.interestCount else {
            throw ProfileInputError.interestCount(expected: Self.interestCount)
        }
        guard !cleanInterests.contains(where: \.isEmpty) else { throw ProfileInputError.emptyInterest }
        guard Set(cleanInterests).count == Self.interestCount else {
            throw ProfileInputError.duplicateInterest
        }
        if let unsupportedInterest = cleanInterests.first(where: { !InterestCatalog.interests.contains($0) }) {
            throw ProfileInputError.unsupportedInterest(unsupportedInterest)
        }

        self.nickname = cleanNickname
        self.currentStatus = cleanCurrentStatus
        self.emoji = emoji
        self.interests = cleanInterests
        self.mbti = mbti
    }

    private static func isEmoji(_ value: String) -> Bool {
        guard value.count == 1 else { return false }

        let scalars = Array(value.unicodeScalars)
        if isKeycapSequence(scalars) { return true }
        if scalars.contains(where: { $0.properties.isEmojiPresentation }) { return true }

        let hasEmojiVariationSelector = scalars.contains { $0.value == 0xFE0F }
        return hasEmojiVariationSelector && scalars.contains {
            $0.properties.isEmoji && !isKeycapBase($0)
        }
    }

    private static func isKeycapSequence(_ scalars: [Unicode.Scalar]) -> Bool {
        guard let first = scalars.first,
              scalars.last?.value == 0x20E3,
              isKeycapBase(first)
        else { return false }

        return scalars.count == 2
            || (scalars.count == 3 && scalars[1].value == 0xFE0F)
    }

    private static func isKeycapBase(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value == 0x23
            || scalar.value == 0x2A
            || (0x30...0x39).contains(scalar.value)
    }
}
