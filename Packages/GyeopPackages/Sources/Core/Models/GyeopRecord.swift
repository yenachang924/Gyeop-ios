import Foundation

/// "겹" = 인증된 만남 1회. 물리적 교환(또는 신호 성사)에서만 생성된다.
/// `id`는 `GyeopID.make`의 결정적 해시 — 양쪽 기기가 독립적으로 같은 값을 계산해
/// 서버에서 자연스럽게 중복이 제거된다 (Telemetry.swift 참조).
public struct GyeopRecord: Codable, Hashable, Sendable, Identifiable {
    public enum Method: String, Codable, Sendable {
        /// 시뮬레이터·개발용 목업 교환
        case mock
        /// MultipeerConnectivity 근접 교환
        case multipeer
        /// NearbyInteraction UWB 자동 트리거
        case uwb
        /// 여가 신호 성사
        case signal
    }

    public let id: String
    /// 상대에게서 받은 카드
    public let counterpartCard: CardSnapshot
    public let method: Method
    public let occurredAt: Date

    public init(id: String, counterpartCard: CardSnapshot, method: Method, occurredAt: Date) {
        self.id = id
        self.counterpartCard = counterpartCard
        self.method = method
        self.occurredAt = occurredAt
    }
}
