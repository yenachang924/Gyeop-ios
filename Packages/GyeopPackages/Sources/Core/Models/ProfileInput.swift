import Foundation

public enum ProfileInputError: Error, Equatable, Sendable {
    case emptyNickname
    case emptyCurrentStatus
    case currentStatusTooLong(maximum: Int)
    case invalidEmoji
    case interestCount(expected: Int)
    case emptyInterest
    case duplicateInterest
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
        guard emoji.count == 1, !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProfileInputError.invalidEmoji
        }
        guard cleanInterests.count == Self.interestCount else {
            throw ProfileInputError.interestCount(expected: Self.interestCount)
        }
        guard !cleanInterests.contains(where: \.isEmpty) else { throw ProfileInputError.emptyInterest }
        guard Set(cleanInterests).count == Self.interestCount else {
            throw ProfileInputError.duplicateInterest
        }

        self.nickname = cleanNickname
        self.currentStatus = cleanCurrentStatus
        self.emoji = emoji
        self.interests = cleanInterests
        self.mbti = mbti
    }
}
