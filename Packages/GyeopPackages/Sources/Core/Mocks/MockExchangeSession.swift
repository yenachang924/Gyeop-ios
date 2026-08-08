import Foundation

/// 스크립트된 목업 교환 세션. MPC/UWB는 실기기 전용이므로
/// 시뮬레이터·타 세션 개발·테스트는 전부 이걸로 돈다.
///
/// 기본 스크립트: searching → peerFound → connecting → cardReceived → completed
public actor MockExchangeSession: ExchangeSession {
    public nonisolated let events: AsyncStream<ExchangeEvent>
    private let continuation: AsyncStream<ExchangeEvent>.Continuation

    private let counterpart: CardSnapshot
    private let stepDelay: Duration
    private let failure: ExchangeFailure?
    private var task: Task<Void, Never>?

    /// - Parameters:
    ///   - counterpart: 교환 상대로 연기할 카드 (기본: 샘플 러너)
    ///   - stepDelay: 이벤트 간 간격 (테스트는 .zero, UI 데모는 수백 ms)
    ///   - failure: 지정 시 cardReceived 대신 해당 실패로 끝난다
    public init(
        counterpart: CardSnapshot = MockData.sampleCards[0],
        stepDelay: Duration = .milliseconds(600),
        failure: ExchangeFailure? = nil
    ) {
        (events, continuation) = AsyncStream.makeStream(of: ExchangeEvent.self)
        self.counterpart = counterpart
        self.stepDelay = stepDelay
        self.failure = failure
    }

    public func start(broadcasting card: CardSnapshot) async throws {
        let span = ExchangePhase.total.begin()
        await MetricCounter.shared.increment(Metric.exchangeAttempt)

        task = Task { [continuation, counterpart, stepDelay, failure] in
            func emit(_ event: ExchangeEvent) async -> Bool {
                guard !Task.isCancelled else { return false }
                continuation.yield(event)
                try? await Task.sleep(for: stepDelay)
                return !Task.isCancelled
            }

            guard await emit(.searching),
                  await emit(.peerFound(name: counterpart.nickname)),
                  await emit(.connecting(name: counterpart.nickname))
            else { return }

            if let failure {
                continuation.yield(.failed(failure))
                await MetricCounter.shared.increment(Metric.exchangeFailure)
                span.end(success: false)
                continuation.finish()
                return
            }

            guard await emit(.cardReceived(counterpart)) else { return }

            let record = GyeopRecord(
                id: GyeopID.make(
                    participantA: card.ownerID,
                    participantB: counterpart.ownerID,
                    serverCorrectedDate: .now
                ),
                counterpartCard: counterpart,
                method: .mock,
                occurredAt: .now
            )
            continuation.yield(.completed(record))
            await MetricCounter.shared.increment(Metric.exchangeSuccess)
            span.end()
            continuation.finish()
        }
    }

    public func cancel() {
        task?.cancel()
        continuation.yield(.failed(.cancelled))
        continuation.finish()
    }
}
