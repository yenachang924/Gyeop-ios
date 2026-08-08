import Core
import Testing
@testable import GyeopKit

private let sampleCard = MockData.sampleCards[0]

@Suite("ExchangeStateMachine — 전이")
struct ExchangeStateMachineTests {
    @Test("idle에서 start하면 searching + .searching 방출")
    func startFromIdle() {
        var machine = ExchangeStateMachine()
        let effects = machine.reduce(.start)
        #expect(machine.state == .searching)
        #expect(effects == [.emit(.searching)])
    }

    @Test("searching에서 피어 발견 — 내가 초대할 때 invitePeer도 함께 나온다")
    func peerDiscoveredAsInitiator() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        let effects = machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        #expect(machine.state == .peerFound(name: "상대"))
        #expect(effects == [.emit(.peerFound(name: "상대")), .invitePeer(name: "상대")])
    }

    @Test("searching에서 피어 발견 — 내가 초대하지 않을 때는 invitePeer 없음")
    func peerDiscoveredAsResponder() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        let effects = machine.reduce(.peerDiscovered(name: "상대", shouldInvite: false))
        #expect(machine.state == .peerFound(name: "상대"))
        #expect(effects == [.emit(.peerFound(name: "상대"))])
    }

    @Test("peerFound → connecting: 이름이 일치해야 전이한다")
    func peerFoundToConnectingRequiresMatchingName() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))

        let mismatched = machine.reduce(.peerConnecting(name: "다른사람"))
        #expect(mismatched.isEmpty)
        #expect(machine.state == .peerFound(name: "상대"))

        let effects = machine.reduce(.peerConnecting(name: "상대"))
        #expect(machine.state == .connecting(name: "상대"))
        #expect(effects == [.emit(.connecting(name: "상대"))])
    }

    @Test("searching에서 바로 peerConnecting이 오면 peerFound를 합성한다 (상대가 먼저 초대)")
    func synthesizesPeerFoundWhenConnectingArrivesFirst() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        let effects = machine.reduce(.peerConnecting(name: "상대"))
        #expect(machine.state == .connecting(name: "상대"))
        #expect(effects == [.emit(.peerFound(name: "상대")), .emit(.connecting(name: "상대"))])
    }

    @Test("peerFound에서 같은 피어를 잃으면 searching으로 복귀 (이벤트 재방출 없음)")
    func peerLostReturnsToSearching() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        let effects = machine.reduce(.peerLost(name: "상대"))
        #expect(machine.state == .searching)
        #expect(effects.isEmpty)
    }

    @Test("connecting → connected: sendCard를 요청하고 awaitingCard로 전이")
    func connectedRequestsSendCard() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        let effects = machine.reduce(.peerConnected(name: "상대"))
        #expect(machine.state == .awaitingCard(name: "상대"))
        #expect(effects == [.sendCard])
    }

    @Test("awaitingCard에서 카드 수신 — cardReceived 방출, finish는 없음(액터가 GyeopRecord 생성 후 처리)")
    func cardReceivedCompletesWithoutFinishEffect() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        machine.reduce(.peerConnected(name: "상대"))
        let effects = machine.reduce(.cardDataReceived(sampleCard))
        #expect(machine.state == .completed(sampleCard))
        #expect(effects == [.emit(.cardReceived(sampleCard))])
    }

    @Test("종료 상태(completed) 이후 입력은 전부 무시된다")
    func ignoresInputAfterCompletion() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        machine.reduce(.peerConnected(name: "상대"))
        machine.reduce(.cardDataReceived(sampleCard))

        let effects = machine.reduce(.timedOut)
        #expect(effects.isEmpty)
        #expect(machine.state == .completed(sampleCard))
    }

    @Test("연결 끊김 시 재시도 한도 내면 searching으로 복귀 + retried 효과")
    func retriesOnDisconnectWithinLimit() {
        var machine = ExchangeStateMachine(maxRetries: 2)
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))

        let effects = machine.reduce(.peerDisconnected(name: "상대"))
        #expect(machine.state == .searching)
        #expect(effects == [.retried, .emit(.searching)])
    }

    @Test("재시도 한도를 초과하면 peerLost로 실패하고 finish된다")
    func failsAfterExhaustingRetries() {
        var machine = ExchangeStateMachine(maxRetries: 1)
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        machine.reduce(.peerDisconnected(name: "상대")) // 1회 재시도 소진

        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        let effects = machine.reduce(.peerDisconnected(name: "상대")) // 한도 초과

        #expect(machine.state == .failed(.peerLost))
        #expect(effects == [.emit(.failed(.peerLost)), .finish])
    }

    @Test("awaitingCard에서 연결이 끊기면 재시도 없이 바로 peerLost 실패")
    func disconnectDuringTransferFailsImmediately() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        machine.reduce(.peerConnected(name: "상대"))

        let effects = machine.reduce(.peerDisconnected(name: "상대"))
        #expect(machine.state == .failed(.peerLost))
        #expect(effects == [.emit(.failed(.peerLost)), .finish])
    }

    @Test("awaitingCard에서 전송 실패는 transferCorrupted로 끝난다")
    func transferFailureDuringAwaitingCard() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        machine.reduce(.peerConnecting(name: "상대"))
        machine.reduce(.peerConnected(name: "상대"))

        let effects = machine.reduce(.transferFailed)
        #expect(machine.state == .failed(.transferCorrupted))
        #expect(effects == [.emit(.failed(.transferCorrupted)), .finish])
    }

    @Test("어느 단계에서든 timedOut은 timedOut 실패로 끝난다", arguments: [
        ExchangeInput.start,
        .peerDiscovered(name: "상대", shouldInvite: true),
        .peerConnecting(name: "상대"),
        .peerConnected(name: "상대"),
    ])
    func timeoutAtAnyStage(upTo lastInput: ExchangeInput) {
        var machine = ExchangeStateMachine()
        let script: [ExchangeInput] = [.start, .peerDiscovered(name: "상대", shouldInvite: true), .peerConnecting(name: "상대"), .peerConnected(name: "상대")]
        for input in script {
            machine.reduce(input)
            if input == lastInput { break }
        }
        let effects = machine.reduce(.timedOut)
        #expect(machine.state == .failed(.timedOut))
        #expect(effects == [.emit(.failed(.timedOut)), .finish])
    }

    @Test("어느 단계에서든 cancelled는 cancelled 실패로 끝난다")
    func cancelDuringConnecting() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))
        let effects = machine.reduce(.cancelled)
        #expect(machine.state == .failed(.cancelled))
        #expect(effects == [.emit(.failed(.cancelled)), .finish])
    }

    @Test("무관한 피어의 discover/lost는 무시된다")
    func ignoresUnrelatedPeerEvents() {
        var machine = ExchangeStateMachine()
        machine.reduce(.start)
        machine.reduce(.peerDiscovered(name: "상대", shouldInvite: true))

        let effects = machine.reduce(.peerLost(name: "다른사람"))
        #expect(effects.isEmpty)
        #expect(machine.state == .peerFound(name: "상대"))
    }
}

@Suite("ExchangeTieBreak")
struct ExchangeTieBreakTests {
    @Test("두 기기가 반대 결론을 내려야 동시 초대 경합이 없다")
    func symmetricOppositeDecision() {
        let a = "user-a"
        let b = "user-b"
        #expect(ExchangeTieBreak.shouldInitiate(local: a, remote: b) != ExchangeTieBreak.shouldInitiate(local: b, remote: a))
    }

    @Test("사전순으로 작은 쪽이 초대한다")
    func lexicographicallySmallerInitiates() {
        #expect(ExchangeTieBreak.shouldInitiate(local: "aaa", remote: "bbb"))
        #expect(!ExchangeTieBreak.shouldInitiate(local: "bbb", remote: "aaa"))
    }
}
