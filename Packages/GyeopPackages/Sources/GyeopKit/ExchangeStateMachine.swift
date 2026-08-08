import Core
import Foundation

// 카드 맞대기 상태 머신 — MultipeerConnectivity(실기기 전용)에서 완전히 분리된 순수 전이 로직.
// MC delegate 콜백은 아래 ExchangeInput으로 번역되고, reduce()가 다음 상태와
// 수행할 부작용(ExchangeEffect)만 반환한다. MC 프레임워크 없이 시뮬레이터·CI에서
// 전 전이 케이스를 단위 테스트하기 위해 이렇게 쪼갰다.

/// 상태 머신 내부 상태. `ExchangeEvent`(공개 이벤트)와는 별개 — 여기엔 재시도 판단에
/// 필요한 세부 상태(어느 피어와 어느 단계인지)가 더 들어간다.
enum ExchangeState: Sendable, Equatable {
    case idle
    case searching
    case peerFound(name: String)
    case connecting(name: String)
    case awaitingCard(name: String)
    /// 카드까지 받은 종료 상태. 실제 GyeopRecord 생성(Date.now 필요)은 액터가 담당한다.
    case completed(CardSnapshot)
    case failed(ExchangeFailure)
}

/// MC delegate 콜백을 번역한 입력. 이름(String)은 MCPeerID.displayName에 대응한다.
enum ExchangeInput: Sendable, Equatable {
    case start
    /// shouldInvite: 발견 직후 내가 초대를 보낼지(tie-break 결과) — ExchangeTieBreak 참조
    case peerDiscovered(name: String, shouldInvite: Bool)
    case peerLost(name: String)
    case peerConnecting(name: String)
    case peerConnected(name: String)
    case peerDisconnected(name: String)
    case cardDataReceived(CardSnapshot)
    case transferFailed
    case timedOut
    case cancelled
}

/// 머신이 요청하는 부작용. 실제 MC 호출·이벤트 방출은 전부 액터(MultipeerExchangeSession) 몫이다.
enum ExchangeEffect: Sendable, Equatable {
    case invitePeer(name: String)
    case sendCard
    case emit(ExchangeEvent)
    /// 재시도 진입 — 액터가 Metric.exchangeRetry 집계 + 락 해제(activePeerName 초기화)를 한다
    case retried
    /// 세션 종료 — 액터가 advertiser/browser/session 정리 + 스트림 종료
    case finish
}

/// 순수 상태 전이. Sendable 값 타입이라 액터 밖에서도, 테스트에서도 자유롭게 다룬다.
struct ExchangeStateMachine: Sendable {
    private(set) var state: ExchangeState = .idle
    private var retryCount = 0
    private let maxRetries: Int

    init(maxRetries: Int = ExchangeConstants.maxConnectionRetries) {
        self.maxRetries = maxRetries
    }

    @discardableResult
    mutating func reduce(_ input: ExchangeInput) -> [ExchangeEffect] {
        // 종료 상태 이후 도착하는 지연 콜백은 조용히 버린다 (완료/실패 후 재처리 금지).
        switch state {
        case .completed, .failed:
            return []
        default:
            break
        }

        switch (state, input) {
        case (.idle, .start):
            state = .searching
            return [.emit(.searching)]

        case (.searching, .peerDiscovered(let name, let shouldInvite)):
            state = .peerFound(name: name)
            return [.emit(.peerFound(name: name))] + (shouldInvite ? [.invitePeer(name: name)] : [])

        // 브라우저가 아직 피어를 못 찾았는데 어드버타이저 쪽에서 먼저 세션이 열리는 경우
        // (상대가 나를 먼저 초대) — peerFound를 합성해 이벤트 순서를 지킨다.
        case (.searching, .peerConnecting(let name)):
            state = .connecting(name: name)
            return [.emit(.peerFound(name: name)), .emit(.connecting(name: name))]

        case (.peerFound(let found), .peerConnecting(let connecting)) where found == connecting:
            state = .connecting(name: found)
            return [.emit(.connecting(name: found))]

        case (.peerFound(let found), .peerLost(let lost)) where found == lost:
            state = .searching
            return []

        case (.connecting(let name), .peerConnected(let connected)) where name == connected:
            state = .awaitingCard(name: name)
            return [.sendCard]

        case (.connecting(let name), .peerDisconnected(let lost)) where name == lost:
            if retryCount < maxRetries {
                retryCount += 1
                state = .searching
                return [.retried, .emit(.searching)]
            }
            state = .failed(.peerLost)
            return [.emit(.failed(.peerLost)), .finish]

        case (.awaitingCard, .cardDataReceived(let card)):
            state = .completed(card)
            return [.emit(.cardReceived(card))]

        case (.awaitingCard(let name), .peerDisconnected(let lost)) where name == lost:
            state = .failed(.peerLost)
            return [.emit(.failed(.peerLost)), .finish]

        case (.awaitingCard, .transferFailed):
            state = .failed(.transferCorrupted)
            return [.emit(.failed(.transferCorrupted)), .finish]

        case (_, .timedOut):
            state = .failed(.timedOut)
            return [.emit(.failed(.timedOut)), .finish]

        case (_, .cancelled):
            state = .failed(.cancelled)
            return [.emit(.failed(.cancelled)), .finish]

        default:
            // 무관한 피어의 발견/소실, 중복 콜백 등 — 안전하게 무시.
            return []
        }
    }
}

/// 두 기기가 서로를 동시에 초대하는 경합을 막는 결정적 규칙.
/// 대칭 프로토콜(양쪽 다 advertiser+browser)에서 누가 초대를 보낼지는
/// 순전히 표시 이름 비교로 정한다 — 별도 조율 없이 양쪽이 같은 결론에 도달해야 한다.
enum ExchangeTieBreak {
    static func shouldInitiate(local: String, remote: String) -> Bool {
        local < remote
    }
}
