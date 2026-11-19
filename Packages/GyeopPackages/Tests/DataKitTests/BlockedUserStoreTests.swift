import Foundation
import Testing
@testable import DataKit

@Suite("BlockedUserStore")
struct BlockedUserStoreTests {
    @Test("blocks survive a new store instance and keep full owner identities")
    func persistsFullIdentities() async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        let store = BlockedUserStore(fileURL: file)
        try await store.block(ownerID: "first-same1234", nickname: "첫 번째")
        try await store.block(ownerID: "other-same1234", nickname: "두 번째")

        let restored = try await BlockedUserStore(fileURL: file).list()

        #expect(Set(restored.map(\.ownerID)) == ["first-same1234", "other-same1234"])
        #expect(restored.first(where: { $0.ownerID == "first-same1234" })?.nickname == "첫 번째")
    }

    @Test("blocking one identity again updates its label without duplicate entries")
    func deduplicatesOwners() async throws {
        let store = BlockedUserStore(inMemory: true)
        try await store.block(ownerID: "owner", nickname: "Before")
        try await store.block(ownerID: "owner", nickname: "After")
        let blocked = try await store.list()
        #expect(blocked.count == 1)
        #expect(blocked.first?.nickname == "After")
    }

    @Test("unblock removes only the selected full identity and remains removed after relaunch")
    func unblocksPersistently() async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        let store = BlockedUserStore(fileURL: file)
        try await store.block(ownerID: "first-same1234")
        try await store.block(ownerID: "other-same1234")
        try await store.unblock(ownerID: "first-same1234")
        try await store.unblock(ownerID: "missing")

        let restored = try await BlockedUserStore(fileURL: file).list()
        #expect(restored.map(\.ownerID) == ["other-same1234"])
    }

    @Test("clearing deletes all local block entries persistently")
    func clearsPersistently() async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        let store = BlockedUserStore(fileURL: file)
        try await store.block(ownerID: "owner")
        try await store.clear()
        try await store.clear()
        #expect(try await BlockedUserStore(fileURL: file).list().isEmpty)
    }

    @Test("corrupt disk contents fail closed and are not silently replaced by a block")
    func rejectsCorruptData() async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let corrupt = Data("not-json".utf8)
        try corrupt.write(to: file)
        let store = BlockedUserStore(fileURL: file)
        await #expect(throws: BlockedUserStore.Error.invalidStoredData) { try await store.list() }
        await #expect(throws: BlockedUserStore.Error.invalidStoredData) {
            try await store.block(ownerID: "owner")
        }
        #expect(try Data(contentsOf: file) == corrupt)
    }

    @Test("account deletion can deliberately clear a corrupted block file")
    func clearsCorruptDataExplicitly() async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: file)
        let store = BlockedUserStore(fileURL: file)
        try await store.clear()
        #expect(try await store.list().isEmpty)
    }

    @Test(arguments: [
        #"[{"ownerID":""}]"#,
        #"[{"ownerID":"owner"},{"ownerID":"owner"}]"#,
        #"[{"ownerID":"owner","nickname":"fuck"}]"#
    ])
    func rejectsInvalidDecodedEntries(_ json: String) async throws {
        let file = makeFileURL()
        defer { removeTestDirectory(file) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: file)
        let store = BlockedUserStore(fileURL: file)
        await #expect(throws: BlockedUserStore.Error.invalidStoredData) { try await store.list() }
    }

    @Test("a blocked user's abusive label is not reproduced in the settings list")
    func storesOnlySafeOptionalLabels() async throws {
        let store = BlockedUserStore(inMemory: true)
        try await store.block(ownerID: "owner", nickname: "fuck")
        let blocked = try await store.list()
        #expect(blocked.first?.ownerID == "owner")
        #expect(blocked.first?.nickname == nil)
    }

    @Test("failed writes throw instead of showing a successful block")
    func reportsWriteFailure() async throws {
        let parent = makeFileURL()
        defer { removeTestDirectory(parent) }
        try FileManager.default.createDirectory(at: parent.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("file-in-place-of-directory".utf8).write(to: parent)
        let store = BlockedUserStore(fileURL: parent.appendingPathComponent("blocked.json"))

        await #expect(throws: BlockedUserStore.Error.persistenceFailed) {
            try await store.block(ownerID: "owner")
        }
    }

    @Test("blank or malformed identities cannot be persisted")
    func rejectsInvalidIdentity() async throws {
        let store = BlockedUserStore(inMemory: true)
        for ownerID in ["", " ", " padded ", "owner\u{0000}id"] {
            await #expect(throws: BlockedUserStore.Error.invalidOwnerID) {
                try await store.block(ownerID: ownerID)
            }
        }
        #expect(try await store.list().isEmpty)
    }

    private func makeFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("gyeop-block-tests-\(UUID().uuidString)")
            .appendingPathComponent("blocked-users.json")
    }

    private func removeTestDirectory(_ file: URL) {
        try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
    }
}
