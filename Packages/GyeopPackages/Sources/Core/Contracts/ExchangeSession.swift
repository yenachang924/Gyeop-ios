import Foundation

/// 카드 맞대기 한 판의 이벤트. `ExchangeSession.events`로 흘러온다.
/// UI는 이 스트림만 구독한다 — MPC/UWB 세부는 GyeopKit 안에 갇힌다.
public enum ExchangeEvent: Sendable, Equatable {
    /// 주변 러너 탐색 시작
    case searching
    /// 피어 발견 (표시용 이름)
    case peerFound(name: String)
    /// 연결 수립 중
    case connecting(name: String)
    /// 상대 카드 수신 완료
    case cardReceived(CardSnapshot)
    /// 겹 성립 — 기록까지 끝난 최종 이벤트
    case completed(GyeopRecord)
    /// 실패 (스트림은 이후 종료된다)
    case failed(ExchangeFailure)
}

public enum ExchangeFailure: String, Sendable, Error, Equatable {
    case peerLost
    case timedOut
    case transferCorrupted
    case cancelled
}

/// 카드 맞대기 세션 계약.
///
/// 소유: GyeopKit 세션이 MPC(→ UWB 승격) 실구현을 제공한다.
/// 시뮬레이터·다른 세션은 `MockExchangeSession`으로 개발한다 (MPC/UWB는 실기기 전용).
public protocol ExchangeSession: Sendable {
    /// 세션 생애 동안의 이벤트 스트림. `completed` 또는 `failed` 후 종료된다.
    var events: AsyncStream<ExchangeEvent> { get }

    /// 내 카드를 들고 탐색·교환을 시작한다.
    func start(broadcasting card: CardSnapshot) async throws

    /// 교환 중단. 스트림은 `failed(.cancelled)` 후 종료된다.
    func cancel() async
}
