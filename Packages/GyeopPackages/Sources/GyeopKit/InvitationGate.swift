import Foundation
import Synchronization

/// MPC의 동기 초대 콜백에서 카드 전송 이전에 전체 소유자 ID와 로컬 차단을 검사한다.
final class InvitationGate: Sendable {
    private struct State {
        var identities: [String: PeerIdentity] = [:]
        var approvedPeers: Set<String> = []
        var lockedPeer: String?
        var isFinished = false
    }

    private let localOwnerID: String
    private let blockedOwnerIDs: Set<String>
    private let state = Mutex(State())

    init(localOwnerID: String, blockedOwnerIDs: Set<String> = []) {
        self.localOwnerID = localOwnerID
        self.blockedOwnerIDs = blockedOwnerIDs
    }

    func registerDiscovery(_ peer: String, info: [String: String]?) -> PeerIdentity? {
        guard let identity = PeerIdentity.fromDiscovery(info),
              identity.ownerID != localOwnerID,
              !blockedOwnerIDs.contains(identity.ownerID) else { return nil }
        return state.withLock { state in
            guard !state.isFinished else { return nil }
            if let existing = state.identities[peer], existing != identity {
                state.identities = state.identities.filter { $0.key != peer }
                state.approvedPeers = state.approvedPeers.subtracting([peer])
                return nil
            }
            state.identities = state.identities.merging([peer: identity]) { _, new in new }
            return identity
        }
    }

    func tryAccept(_ peer: String, context: Data?) -> Bool {
        guard let supplied = PeerIdentity.fromContext(context) else { return false }
        return state.withLock { state in
            guard !state.isFinished, state.identities[peer] == supplied,
                  !blockedOwnerIDs.contains(supplied.ownerID),
                  state.lockedPeer == nil || state.lockedPeer == peer else { return false }
            state.lockedPeer = peer
            state.approvedPeers = state.approvedPeers.union([peer])
            return true
        }
    }

    func approveOutgoing(_ peer: String) -> Bool {
        state.withLock { state in
            guard !state.isFinished, state.lockedPeer == peer,
                  let identity = state.identities[peer],
                  !blockedOwnerIDs.contains(identity.ownerID) else { return false }
            state.approvedPeers = state.approvedPeers.union([peer])
            return true
        }
    }

    func allowsSending(to peer: String) -> Bool {
        state.withLock { state in
            guard !state.isFinished, state.lockedPeer == peer,
                  state.approvedPeers.contains(peer), let identity = state.identities[peer] else { return false }
            return !blockedOwnerIDs.contains(identity.ownerID)
        }
    }

    func ownerID(for peer: String) -> String? {
        state.withLock { state in
            guard !state.isFinished, let identity = state.identities[peer],
                  !blockedOwnerIDs.contains(identity.ownerID) else { return nil }
            return identity.ownerID
        }
    }

    func matchesPayloadOwner(_ ownerID: String, from peer: String) -> Bool {
        state.withLock { state in
            !state.isFinished && state.lockedPeer == peer && state.approvedPeers.contains(peer)
                && state.identities[peer]?.ownerID == ownerID && !blockedOwnerIDs.contains(ownerID)
        }
    }

    func forget(_ peer: String) {
        state.withLock { state in
            // 상대는 완료 직후 광고부터 종료할 수 있다. 연결의 승인 신원은 전송 종료까지 유지한다.
            guard state.lockedPeer != peer || !state.approvedPeers.contains(peer) else { return }
            state.identities = state.identities.filter { $0.key != peer }
            state.approvedPeers = state.approvedPeers.subtracting([peer])
        }
    }

    func sync(lockedPeer: String?) {
        state.withLock { state in
            state.lockedPeer = lockedPeer
            if lockedPeer == nil { state.approvedPeers = [] }
        }
    }

    func finish() {
        state.withLock { state in
            state.isFinished = true
            state.approvedPeers = []
        }
    }
}
