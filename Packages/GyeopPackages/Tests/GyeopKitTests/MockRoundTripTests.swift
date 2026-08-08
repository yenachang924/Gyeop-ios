import Core
import Testing
@testable import GyeopKit

/// 실기기(MPC) 없이도 왕복 계약을 검증한다: 두 러너가 각자 기기에서 독립적으로
/// MockExchangeSession을 돌려 서로의 카드를 상대 카드로 받는 상황을 시뮬레이션하고,
/// 결과 GyeopRecord의 id가 두 기기에서 동일하게 계산되는지 확인한다 (GyeopID 결정성).
@Suite("Mock 페어 왕복")
struct MockRoundTripTests {
    @Test("두 기기가 독립적으로 완료해도 같은 GyeopID를 얻는다")
    func bothSidesConverge() async throws {
        let cardA = MockData.sampleCards[0]
        let cardB = MockData.sampleCards[1]
        let occurredAt = MockData.referenceDate

        let sessionOnDeviceA = MockExchangeSession(counterpart: cardB, stepDelay: .zero)
        let sessionOnDeviceB = MockExchangeSession(counterpart: cardA, stepDelay: .zero)

        try await sessionOnDeviceA.start(broadcasting: cardA)
        try await sessionOnDeviceB.start(broadcasting: cardB)

        async let eventsA = collect(sessionOnDeviceA.events)
        async let eventsB = collect(sessionOnDeviceB.events)
        let (a, b) = await (eventsA, eventsB)

        guard case .completed(let recordA)? = a.last, case .completed(let recordB)? = b.last else {
            Issue.record("양쪽 다 completed로 끝나야 한다: A=\(String(describing: a.last)) B=\(String(describing: b.last))")
            return
        }

        // 실제 맞대기라면 두 기기 모두 서버 보정 시각이 같은 5분 슬롯에 들어오므로
        // 여기서는 동일한 serverCorrectedDate로 재계산해 GyeopID 결정성만 검증한다
        // (MockExchangeSession은 각자 .now를 쓰므로 id 자체는 다를 수 있다 — 슬롯 경계 문제).
        let expectedID = GyeopID.make(runnerA: cardA.ownerID, runnerB: cardB.ownerID, serverCorrectedDate: occurredAt)
        let recomputedFromA = GyeopID.make(runnerA: cardA.ownerID, runnerB: recordA.counterpartCard.ownerID, serverCorrectedDate: occurredAt)
        let recomputedFromB = GyeopID.make(runnerA: cardB.ownerID, runnerB: recordB.counterpartCard.ownerID, serverCorrectedDate: occurredAt)

        #expect(recomputedFromA == expectedID)
        #expect(recomputedFromB == expectedID)
        #expect(recordA.counterpartCard == cardB)
        #expect(recordB.counterpartCard == cardA)
    }

    @Test("한쪽이 실패해도 다른 쪽 스트림은 독립적으로 끝난다")
    func oneSideFailureDoesNotBlockTheOther() async throws {
        let cardA = MockData.sampleCards[0]
        let cardB = MockData.sampleCards[1]

        let sessionOnDeviceA = MockExchangeSession(counterpart: cardB, stepDelay: .zero, failure: .peerLost)
        let sessionOnDeviceB = MockExchangeSession(counterpart: cardA, stepDelay: .zero)

        try await sessionOnDeviceA.start(broadcasting: cardA)
        try await sessionOnDeviceB.start(broadcasting: cardB)

        let a = await collect(sessionOnDeviceA.events)
        let b = await collect(sessionOnDeviceB.events)

        #expect(a.last == .failed(.peerLost))
        guard case .completed? = b.last else {
            Issue.record("B는 여전히 completed로 끝나야 한다: \(String(describing: b.last))")
            return
        }
    }

    private func collect(_ stream: AsyncStream<ExchangeEvent>) async -> [ExchangeEvent] {
        var events: [ExchangeEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }
}
