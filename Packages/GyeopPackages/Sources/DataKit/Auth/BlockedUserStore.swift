import Core
import Foundation

public struct BlockedUser: Codable, Equatable, Sendable, Identifiable {
    public let ownerID: String
    public let nickname: String?
    public var id: String { ownerID }

    public init(ownerID: String, nickname: String? = nil) {
        self.ownerID = ownerID
        self.nickname = nickname
    }
}

/// 차단은 이 기기에만 적용한다. 전체 ownerID를 비교하며 접미사나 닉네임을 식별자로 쓰지 않는다.
/// 파일 오류·손상은 빈 목록으로 취급하지 않는다. 쓰기는 원자적으로 완료된 뒤에만 성공한다.
public actor BlockedUserStore {
    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidOwnerID
        case invalidStoredData
        case persistenceFailed
    }

    private static let maximumOwnerIDScalars = 256
    private static let maximumNicknameCharacters = 80
    private let fileURL: URL?
    private var memoryEntries: [BlockedUser] = []

    public init(fileURL: URL? = nil, inMemory: Bool = false) {
        self.fileURL = inMemory ? nil : (fileURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("Gyeop")
            .appendingPathComponent("blocked-users.json"))
    }

    public func list() throws -> [BlockedUser] {
        guard let fileURL else { return memoryEntries }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        } catch {
            throw Error.persistenceFailed
        }
        let entries: [BlockedUser]
        do {
            entries = try JSONDecoder().decode([BlockedUser].self, from: data)
        } catch {
            throw Error.invalidStoredData
        }
        guard entries.allSatisfy({ Self.isValid(ownerID: $0.ownerID) && Self.isValidLabel($0.nickname) }),
              Set(entries.map(\.ownerID)).count == entries.count
        else { throw Error.invalidStoredData }
        return entries
    }

    public func block(ownerID: String, nickname: String? = nil) throws {
        guard Self.isValid(ownerID: ownerID) else { throw Error.invalidOwnerID }
        let entries = try list().filter { $0.ownerID != ownerID }
        let replacement = BlockedUser(ownerID: ownerID, nickname: Self.safeNickname(nickname))
        try persist((entries + [replacement]).sorted { $0.ownerID < $1.ownerID })
    }

    public func unblock(ownerID: String) throws {
        guard Self.isValid(ownerID: ownerID) else { throw Error.invalidOwnerID }
        try persist(list().filter { $0.ownerID != ownerID })
    }

    /// 계정 삭제는 손상된 파일도 명시적으로 초기화할 수 있다.
    public func clear() throws {
        try persist([])
    }

    private func persist(_ entries: [BlockedUser]) throws {
        guard let fileURL else {
            memoryEntries = entries
            return
        }
        do {
            let data = try JSONEncoder().encode(entries)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw Error.persistenceFailed
        }
    }

    private static func isValid(ownerID: String) -> Bool {
        !ownerID.isEmpty && ownerID.unicodeScalars.count <= maximumOwnerIDScalars
            && !ownerID.unicodeScalars.contains {
                $0.properties.isWhitespace || $0.properties.generalCategory == .control
                    || $0.properties.isDefaultIgnorableCodePoint
            }
    }

    private static func safeNickname(_ nickname: String?) -> String? {
        guard let nickname else { return nil }
        let clean = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ContentModerationPolicy.isAllowed(text: clean) else { return nil }
        return String(clean.prefix(maximumNicknameCharacters))
    }

    private static func isValidLabel(_ nickname: String?) -> Bool {
        guard let nickname else { return true }
        return nickname.count <= maximumNicknameCharacters
            && ContentModerationPolicy.isAllowed(text: nickname)
    }
}
