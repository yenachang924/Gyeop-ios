//
//  Telemetry.swift
//  Gyeop — Core 모듈 (snippets/Telemetry.swift에서 이식, sha256 실구현 포함)
//
//  이 파일이 없으면 나중에 기술 아티클을 쓸 수 없다.
//  측정하지 않은 것은 개선할 수도, 자랑할 수도 없다.
//

import CryptoKit
import Foundation
import OSLog

// MARK: - Logger

/// 앱 전역 로거. 카테고리를 분리해야 Console.app / sysdiagnose에서 필터링이 된다.
public enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gyeop.app"

    /// 카드 맞대기 — MPC 발견/연결/전송, UWB 거리 이벤트
    public static let nearby = Logger(subsystem: subsystem, category: "nearby")
    /// 서버 동기화 — 오프라인 큐, 업로드, 중복 검출
    public static let sync = Logger(subsystem: subsystem, category: "sync")
    /// 렌더링 — 셰이더, 그래프 프레임
    public static let render = Logger(subsystem: subsystem, category: "render")
}

// MARK: - Signpost

/// Instruments에서 구간 측정을 위한 signposter.
/// 아티클 #1 "맞대기 3초 달성기"의 구간별 수치가 여기서 나온다.
public enum Signpost {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gyeop.app"

    public static let nearby = OSSignposter(
        logger: Logger(subsystem: subsystem, category: "signpost.nearby")
    )
    public static let sync = OSSignposter(
        logger: Logger(subsystem: subsystem, category: "signpost.sync")
    )
}

// MARK: - 측정 구간 정의

/// 맞대기 교환의 3구간. 어디가 느린지 모르면 최적화는 추측이 된다.
///
/// 사용:
/// ```swift
/// let span = ExchangePhase.discovery.begin()
/// defer { span.end() }
/// ```
public enum ExchangePhase {
    /// 광고 시작 → 피어 발견
    case discovery
    /// 초대 → 세션 connected
    case connection
    /// 카드 데이터 송수신 완료
    case transfer
    /// 전체 (맞댐 → 교환 완료)
    case total

    var name: StaticString {
        switch self {
        case .discovery: "exchange.discovery"
        case .connection: "exchange.connection"
        case .transfer: "exchange.transfer"
        case .total: "exchange.total"
        }
    }

    public func begin() -> SignpostSpan {
        let id = Signpost.nearby.makeSignpostID()
        let state = Signpost.nearby.beginInterval(name, id: id)
        return SignpostSpan(
            signposter: Signpost.nearby,
            name: name,
            state: state,
            startedAt: .now
        )
    }
}

/// 구간 측정 핸들. `end()`에서 signpost 종료 + 소요시간을 로그로 남긴다.
/// 로그로도 남기는 이유: Instruments 없이 실기기에서 뽑은 수치가 필요할 때가 있다.
public struct SignpostSpan {
    let signposter: OSSignposter
    let name: StaticString
    let state: OSSignpostIntervalState
    let startedAt: ContinuousClock.Instant

    public func end(success: Bool = true) {
        signposter.endInterval(name, state)
        let elapsed = ContinuousClock.Instant.now - startedAt
        let ms = Double(elapsed.components.seconds) * 1000
            + Double(elapsed.components.attoseconds) / 1e15
        let label = String(describing: name)
        Log.nearby.info("\(label, privacy: .public) \(success ? "ok" : "fail", privacy: .public) \(ms, format: .fixed(precision: 1))ms")
    }
}

// MARK: - 카운터

/// 성공/실패/재시도 집계. 일별 스냅샷으로 서버에 올라가 겹 오퍼레이터의 입력이 된다.
public actor MetricCounter {
    public static let shared = MetricCounter()

    private var counts: [String: Int] = [:]

    public init() {}

    public func increment(_ key: String, by n: Int = 1) {
        counts[key, default: 0] += n
    }

    /// 하루치 스냅샷을 뽑고 초기화. 앱 백그라운드 진입 시 서버 업로드.
    public func drain() -> [String: Int] {
        defer { counts.removeAll() }
        return counts
    }

    public func snapshot() -> [String: Int] { counts }
}

/// 집계 키. 문자열 리터럴을 흩뿌리면 나중에 대조가 안 된다.
public enum Metric {
    public static let exchangeAttempt = "exchange.attempt"
    public static let exchangeSuccess = "exchange.success"
    public static let exchangeFailure = "exchange.failure"
    public static let exchangeRetry = "exchange.retry"
    public static let exchangeDuplicate = "exchange.duplicate"   // 멱등성 검증용 — 아티클 #2

    public static let syncQueued = "sync.queued"
    public static let syncUploaded = "sync.uploaded"
    public static let syncConflict = "sync.conflict"
}

// MARK: - 결정적 겹 ID (아티클 #2의 핵심)

/// 오프라인 P2P 교환은 양쪽 기기에서 독립적으로 발생한다.
/// 각자 서버에 올리면 같은 만남이 2건이 된다.
///
/// 두 기기가 **독립적으로 계산해도 같은 값**이 나오는 ID를 만들어
/// 서버에서 자연스럽게 중복이 제거되게 한다.
///
/// - 두 참여자 ID를 정렬해 순서 의존성 제거
/// - 타임슬롯(5분 버킷)으로 양쪽의 미세한 시각 차이를 흡수
/// - 서버 시각 보정값을 쓴다 (기기 시계는 신뢰하지 않는다)
public enum GyeopID {
    public static let slotSeconds: TimeInterval = 300  // 5분

    public static func make(participantA: String, participantB: String, serverCorrectedDate: Date) -> String {
        let pair = [participantA, participantB].sorted().joined(separator: "|")
        let slot = Int(serverCorrectedDate.timeIntervalSince1970 / slotSeconds)
        return DeterministicHash.sha256Hex("\(pair)|\(slot)")
    }
}

/// 결정적 해시 헬퍼. GyeopID와 카드 시드(CardKit)가 공유한다.
public enum DeterministicHash {
    public static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
