import Core
import Foundation

// GyeopKit — 카드 맞대기(MPC → UWB) 소유 세션의 자리.
//
// 여기 들어올 것:
// - MultipeerExchangeSession: ExchangeSession  (발견→초대→수락→전송 상태 머신, CoreHaptics)
// - UWBProximityTrigger                        (NearbyInteraction, 30cm 트리거 — v0.2)
//
// 실기기 전용이다. 시뮬레이터·타 세션은 Core의 MockExchangeSession을 쓴다.
// 실기기 확인이 필요한 항목은 docs/device-required.md에 등록할 것.

/// 교환 프로토콜 상수 — 양 기기가 공유하는 값이라 코드로 고정한다.
public enum ExchangeConstants {
    /// MPC 서비스 타입 (Bonjour 제약: 1~15자, 소문자·숫자·하이픈)
    public static let serviceType = "gyeop-exchange"
    /// UWB 자동 트리거 거리 (m)
    public static let uwbTriggerDistance: Double = 0.3
    /// 맞댐 → 교환 완료 목표 시간 (수용 기준: 3초 이내)
    public static let exchangeTimeBudget: Duration = .seconds(3)
    /// 동일 상대 재맞댐 집계 제한 (24시간 1회)
    public static let recountInterval: TimeInterval = 86_400
}
