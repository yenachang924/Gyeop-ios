import Core
import Foundation
@preconcurrency import MultipeerConnectivity

/// 카드 맞대기(MPC) 실구현. 상태 전이 로직은 ExchangeStateMachine(순수·테스트 가능)이
/// 갖고 있고, 이 액터는 MC delegate 콜백을 상태 머신 입력으로 번역하고 머신이 요청한
/// 부작용(초대·전송·이벤트 방출·타임아웃·종료)을 실행하는 역할만 한다.
///
/// MC delegate 프로토콜은 Objective-C 시절 API라 임의 큐에서 동기 호출된다. actor가
/// 직접 그 프로토콜들을 구현하는 대신, NSObject 서브클래스인 ``ExchangeDelegateProxy``가
/// 콜백을 받아 `Task { await ... }`로 액터 안에 다시 들어와 처리한다.
///
/// 실기기 전용이다. 시뮬레이터·다른 세션 개발은 Core의 `MockExchangeSession`을 쓴다.
public actor MultipeerExchangeSession: ExchangeSession {
    public nonisolated let events: AsyncStream<ExchangeEvent>
    private let continuation: AsyncStream<ExchangeEvent>.Continuation

    private let localOwnerID: String
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let delegateProxy: ExchangeDelegateProxy
    private let invitationGate: InvitationGate
    private let haptics = HapticFeedback()

    private var machine = ExchangeStateMachine()
    private var myCard: CardSnapshot?
    private var knownPeers: [String: MCPeerID] = [:]
    /// 진행 중인 상대 락. 반드시 setActivePeer(_:)로만 쓴다 — 초대 게이트 미러를 함께 갱신해야 한다.
    private var activePeerName: String?
    private var timeoutTask: Task<Void, Never>?
    private var isFinished = false

    private var totalSpan: SignpostSpan?
    private var discoverySpan: SignpostSpan?
    private var connectionSpan: SignpostSpan?
    private var transferSpan: SignpostSpan?

    /// - Parameter displayName: 상대에게 보일 이름. MCPeerID 제약상 UTF-8 63바이트 이내여야 한다.
    public init(displayName: String, ownerID: String, blockedOwnerIDs: Set<String> = []) {
        let peerID = MCPeerID(displayName: displayName)
        localOwnerID = ownerID
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID, discoveryInfo: PeerIdentity(ownerID: ownerID)?.discoveryInfo,
            serviceType: ExchangeConstants.serviceType
        )
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: ExchangeConstants.serviceType)
        let gate = InvitationGate(localOwnerID: ownerID, blockedOwnerIDs: blockedOwnerIDs)
        invitationGate = gate
        delegateProxy = ExchangeDelegateProxy(session: session, gate: gate)
        (events, continuation) = AsyncStream.makeStream(of: ExchangeEvent.self)

        session.delegate = delegateProxy
        advertiser.delegate = delegateProxy
        browser.delegate = delegateProxy
        delegateProxy.target = self
    }

    public func start(broadcasting card: CardSnapshot) async throws {
        guard machine.state == .idle else { return }
        guard card.ownerID == localOwnerID, PeerIdentity(ownerID: localOwnerID) != nil else {
            throw CardPayloadError.decodingFailed
        }
        _ = try CardPayload.encode(card) // 상한 초과 시 광고 시작 전에 던진다
        myCard = card
        await haptics.prepare()
        totalSpan = ExchangePhase.total.begin()
        await MetricCounter.shared.increment(Metric.exchangeAttempt)
        apply(.start)
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    public func cancel() async {
        apply(.cancelled)
    }

    // MARK: - 상태 머신 구동

    private func apply(_ input: ExchangeInput) {
        guard !isFinished else { return }
        let previous = machine.state
        let effects = machine.reduce(input)
        let current = machine.state
        if previous != current {
            updateTelemetryPhase(for: current)
            rescheduleTimeout(for: current)
        }
        for effect in effects {
            perform(effect)
        }
    }

    private func perform(_ effect: ExchangeEffect) {
        switch effect {
        case .invitePeer(let name):
            guard let peer = knownPeers[name], invitationGate.approveOutgoing(name),
                  let identity = PeerIdentity(ownerID: localOwnerID) else {
                apply(.transferFailed)
                return
            }
            do {
                let context = try identity.encodedContext()
                browser.invitePeer(peer, to: session, withContext: context, timeout: connectionTimeoutSeconds)
            } catch {
                apply(.transferFailed)
            }

        case .sendCard:
            sendMyCard()

        case .emit(let event):
            continuation.yield(safeEvent(event))
            if let pattern = Self.hapticPattern(for: event) {
                Task { await haptics.play(pattern) }
            }
            if case .cardReceived(let counterpart) = event {
                Task { await completeExchange(with: counterpart) }
            }
            if case .failed = event {
                Task { await MetricCounter.shared.increment(Metric.exchangeFailure) }
                totalSpan?.end(success: false)
                totalSpan = nil
            }

        case .retried:
            setActivePeer(nil)
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            Task { await MetricCounter.shared.increment(Metric.exchangeRetry) }

        case .releasePeer:
            setActivePeer(nil)

        case .finish:
            teardown()
        }
    }

    private func completeExchange(with counterpart: CardSnapshot) async {
        guard let myCard, let name = activePeerName,
              invitationGate.matchesPayloadOwner(counterpart.ownerID, from: name),
              ContentModerationPolicy.isAllowed(card: counterpart) else {
            continuation.yield(.failed(.transferCorrupted))
            teardown()
            return
        }
        let shared = myCard.sharedInterests(with: counterpart)
        Log.nearby.info("exchange overlap: \(shared.count, privacy: .public) shared interests")

        let record = GyeopRecord(
            id: GyeopID.make(participantA: myCard.ownerID, participantB: counterpart.ownerID, serverCorrectedDate: .now),
            counterpartCard: counterpart,
            method: .multipeer,
            occurredAt: .now
        )
        continuation.yield(.completed(record))
        await haptics.play(.completed)
        await MetricCounter.shared.increment(Metric.exchangeSuccess)
        transferSpan?.end()
        transferSpan = nil
        totalSpan?.end()
        totalSpan = nil
        teardown()
    }

    private func teardown() {
        guard !isFinished else { return }
        isFinished = true
        invitationGate.finish() // 종료 후 도착하는 초대는 게이트가 거절한다
        timeoutTask?.cancel()
        timeoutTask = nil
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        continuation.finish()
    }

    // MARK: - Telemetry · 타임아웃

    private static func hapticPattern(for event: ExchangeEvent) -> HapticPattern? {
        switch event {
        case .peerFound: .peerFound
        case .cardReceived: .connected
        case .failed: .failed
        case .searching, .connecting, .completed: nil
        }
    }

    private func safeEvent(_ event: ExchangeEvent) -> ExchangeEvent {
        switch event {
        case .peerFound: .peerFound(name: "근처 상대")
        case .connecting: .connecting(name: "근처 상대")
        default: event
        }
    }

    private func updateTelemetryPhase(for state: ExchangeState) {
        switch state {
        case .searching:
            if discoverySpan == nil { discoverySpan = ExchangePhase.discovery.begin() }
        case .connecting:
            discoverySpan?.end()
            discoverySpan = nil
            if connectionSpan == nil { connectionSpan = ExchangePhase.connection.begin() }
        case .awaitingCard:
            connectionSpan?.end()
            connectionSpan = nil
            if transferSpan == nil { transferSpan = ExchangePhase.transfer.begin() }
        case .failed:
            discoverySpan?.end(success: false)
            discoverySpan = nil
            connectionSpan?.end(success: false)
            connectionSpan = nil
            transferSpan?.end(success: false)
            transferSpan = nil
        case .idle, .peerFound, .completed:
            break
        }
    }

    private var connectionTimeoutSeconds: Double {
        Double(ExchangeConstants.connectionTimeout.components.seconds)
    }

    private func rescheduleTimeout(for state: ExchangeState) {
        timeoutTask?.cancel()
        timeoutTask = nil

        let duration: Duration?
        switch state {
        case .searching, .peerFound: duration = ExchangeConstants.discoveryTimeout
        case .connecting: duration = ExchangeConstants.connectionTimeout
        case .awaitingCard: duration = ExchangeConstants.transferTimeout
        case .idle, .completed, .failed: duration = nil
        }
        guard let duration else { return }

        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await self?.apply(.timedOut)
        }
    }

    /// activePeerName의 유일한 쓰기 경로 — 초대 게이트(델리게이트 큐에서 동기 판정)와
    /// 액터 쪽 락이 어긋나지 않게 항상 함께 갱신한다.
    private func setActivePeer(_ name: String?) {
        activePeerName = name
        invitationGate.sync(lockedPeer: name)
    }

    // MARK: - MC delegate 콜백 (delegateProxy가 호출)

    fileprivate func handleFoundPeer(_ peerID: MCPeerID) {
        guard let remoteOwnerID = invitationGate.ownerID(for: peerID.displayName) else { return }
        knownPeers[peerID.displayName] = peerID
        guard activePeerName == nil else { return }
        setActivePeer(peerID.displayName)
        let shouldInvite = ExchangeTieBreak.shouldInitiate(local: localOwnerID, remote: remoteOwnerID)
        apply(.peerDiscovered(name: peerID.displayName, shouldInvite: shouldInvite))
    }

    fileprivate func handleLostPeer(_ peerID: MCPeerID) {
        knownPeers.removeValue(forKey: peerID.displayName)
        guard activePeerName == peerID.displayName else { return }
        apply(.peerLost(name: peerID.displayName))
    }

    fileprivate func handleReceivedInvitation(from peerID: MCPeerID, accepted: Bool) {
        knownPeers[peerID.displayName] = peerID
        guard accepted else { return }
        // 게이트가 수락하며 잠갔다면 액터 쪽 락도 맞춘다. 그 사이 다른 피어로 잠긴 희귀한
        // 경합에서는 액터가 우선 — 수락된 세션의 콜백은 activePeerName 가드가 걸러낸다.
        setActivePeer(activePeerName ?? peerID.displayName)
    }

    fileprivate func handleSessionStateChange(_ peerID: MCPeerID, state: MCSessionState) {
        knownPeers[peerID.displayName] = peerID
        if activePeerName == nil, invitationGate.allowsSending(to: peerID.displayName) {
            setActivePeer(peerID.displayName)
        }
        guard activePeerName == peerID.displayName else { return }

        switch state {
        case .connecting:
            guard invitationGate.allowsSending(to: peerID.displayName) else {
                apply(.transferFailed)
                return
            }
            apply(.peerConnecting(name: peerID.displayName))
        case .connected:
            guard invitationGate.allowsSending(to: peerID.displayName) else {
                apply(.transferFailed)
                return
            }
            apply(.peerConnected(name: peerID.displayName))
        case .notConnected:
            apply(.peerDisconnected(name: peerID.displayName))
        @unknown default:
            break
        }
    }

    fileprivate func handleReceivedData(_ data: Data, from peerID: MCPeerID) {
        guard activePeerName == peerID.displayName else { return }
        do {
            let card = try CardPayload.decode(data)
            guard invitationGate.matchesPayloadOwner(card.ownerID, from: peerID.displayName) else {
                apply(.transferFailed)
                return
            }
            apply(.cardDataReceived(card))
        } catch {
            Log.nearby.error("card decode failed: \(String(describing: error), privacy: .public)")
            apply(.transferFailed)
        }
    }

    private func sendMyCard() {
        guard let myCard, let name = activePeerName, let peer = knownPeers[name],
              invitationGate.allowsSending(to: name),
              ContentModerationPolicy.isAllowed(card: myCard) else {
            apply(.transferFailed)
            return
        }
        do {
            let data = try CardPayload.encode(myCard)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            Log.nearby.error("card send failed: \(String(describing: error), privacy: .public)")
            apply(.transferFailed)
        }
    }
}

/// MC delegate(Objective-C 프로토콜) 수신 전담 NSObject. 콜백은 프레임워크가 고른
/// 임의 큐에서 동기로 온다 — 상태를 만지지 않고 즉시 액터로 넘긴다.
private final class ExchangeDelegateProxy: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    weak var target: MultipeerExchangeSession?
    /// 초대 수락(`invitationHandler`)을 액터로 넘기지 않고 여기서 바로 호출하기 위해 필요.
    /// non-Sendable 클로저를 actor 경계 너머로 보내는 걸 피하는 목적도 있다.
    private let session: MCSession
    private let gate: InvitationGate

    init(session: MCSession, gate: InvitationGate) {
        self.session = session
        self.gate = gate
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { [target] in await target?.handleSessionStateChange(peerID, state: state) }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { [target] in await target?.handleReceivedData(data, from: peerID) }
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        // tie-break는 초대 '발신' 방향만 정한다 — 다자 환경에서 제3자 초대를 걸러내는 건
        // 수신 측 몫이다. 이미 다른 상대와 진행 중이거나 종료 후면 거절한다; 거절받은
        // 초대자는 didChange(.notConnected)를 받고 자기 쪽에서 재시도한다.
        let accepted = gate.tryAccept(peerID.displayName, context: context)
        invitationHandler(accepted, accepted ? session : nil)
        Task { [target] in await target?.handleReceivedInvitation(from: peerID, accepted: accepted) }
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard gate.registerDiscovery(peerID.displayName, info: info) != nil else { return }
        Task { [target] in await target?.handleFoundPeer(peerID) }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        gate.forget(peerID.displayName)
        Task { [target] in await target?.handleLostPeer(peerID) }
    }
}
