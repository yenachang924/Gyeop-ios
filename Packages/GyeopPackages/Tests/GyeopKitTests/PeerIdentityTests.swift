import Foundation
import Testing
@testable import GyeopKit

@Suite("Peer identity before card transfer")
struct PeerIdentityTests {
    @Test("전체 ID가 차단됐으면 동일한 마지막 8글자의 다른 ID와 구분한다")
    func blocksExactOwnerBeforeOutboundApproval() throws {
        let blocked = "blocked-12345678"
        let allowed = "allowed-12345678"
        let gate = InvitationGate(localOwnerID: "local", blockedOwnerIDs: [blocked])
        #expect(gate.registerDiscovery("blocked", info: PeerIdentity(ownerID: blocked)?.discoveryInfo) == nil)
        #expect(!gate.approveOutgoing("blocked"))
        #expect(!gate.allowsSending(to: "blocked"))
        #expect(gate.registerDiscovery("allowed", info: PeerIdentity(ownerID: allowed)?.discoveryInfo) != nil)
        gate.sync(lockedPeer: "allowed")
        #expect(gate.approveOutgoing("allowed"))
        #expect(gate.allowsSending(to: "allowed"))
    }

    @Test("발견 정보와 초대의 전체 ID가 다르거나 기존 버전이면 연결하지 않는다")
    func rejectsUnknownAndMismatchedInvitations() throws {
        let gate = InvitationGate(localOwnerID: "local")
        let remote = try #require(PeerIdentity(ownerID: "remote"))
        let other = try #require(PeerIdentity(ownerID: "other"))
        #expect(!gate.tryAccept("remote", context: try remote.encodedContext()))
        _ = gate.registerDiscovery("remote", info: remote.discoveryInfo)
        #expect(!gate.tryAccept("remote", context: nil))
        #expect(!gate.tryAccept("remote", context: try other.encodedContext()))
        #expect(!gate.allowsSending(to: "remote"))
        #expect(gate.tryAccept("remote", context: try remote.encodedContext()))
        #expect(gate.allowsSending(to: "remote"))
        #expect(!gate.matchesPayloadOwner("other", from: "remote"))
        #expect(gate.matchesPayloadOwner("remote", from: "remote"))
    }

    @Test("유효하지 않은 식별자와 초대 크기를 거부한다")
    func rejectsInvalidIdentity() {
        #expect(PeerIdentity(ownerID: "") == nil)
        #expect(PeerIdentity(ownerID: "owner\nspoof") == nil)
        #expect(PeerIdentity.fromContext(Data(repeating: 0, count: PeerIdentity.maximumContextBytes + 1)) == nil)
    }

    @Test("상대의 광고 종료가 진행 중인 전송의 승인된 신원을 없애지 않는다")
    func discoveryLossPreservesActiveApprovedIdentity() throws {
        let gate = InvitationGate(localOwnerID: "local")
        let remote = try #require(PeerIdentity(ownerID: "remote"))
        _ = gate.registerDiscovery("peer", info: remote.discoveryInfo)
        gate.sync(lockedPeer: "peer")
        #expect(gate.approveOutgoing("peer"))

        gate.forget("peer")

        #expect(gate.allowsSending(to: "peer"))
        #expect(gate.matchesPayloadOwner("remote", from: "peer"))
        gate.sync(lockedPeer: nil)
        gate.forget("peer")
        #expect(!gate.matchesPayloadOwner("remote", from: "peer"))
    }
}
