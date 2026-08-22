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
    /// 동일 상대 재맞댐 집계 제한 (24시간 1회) — 실제 판정은 DataKit 소관, GyeopKit은 이벤트만 발행
    public static let recountInterval: TimeInterval = 86_400

    /// 피어 탐색 단계 하드 타임아웃 (목표 3초보다 넉넉히 — 혼잡한 공간 대비)
    public static let discoveryTimeout: Duration = .seconds(20)
    /// 초대 → 세션 connected 단계 타임아웃
    public static let connectionTimeout: Duration = .seconds(10)
    /// connected → 카드 수신 단계 타임아웃
    public static let transferTimeout: Duration = .seconds(5)
    /// 연결 실패 시 같은 판에서 재시도할 최대 횟수 (초과하면 peerLost로 실패)
    public static let maxConnectionRetries = 2

    /// `MCPeerID(displayName:)`의 상한. **UTF-8 바이트 기준**이며, 넘기면 초기화가
    /// 예외를 던져 앱이 죽는다 (글자 수 제한이 아니다).
    public static let maximumPeerNameBytes = 63
    /// 상대 화면에 읽히기 좋은 닉네임 길이 상한 (글자 수).
    public static let maximumPeerNicknameCharacters = 12
}

/// 맞대기에 쓸 피어 표시 이름을 만든다.
///
/// 닉네임에는 길이 제한이 없고(`ProfileInput`은 「지금의 나」만 40자로 막는다) 이모지
/// 한 글자가 25바이트를 넘기도 한다. 글자 수로 자르면 바이트 상한을 넘겨
/// `MCPeerID`가 예외를 던지므로 **바이트를 세면서** 자른다.
///
/// 닉네임이 겹쳐도 피어가 구분되도록 소유자 ID 뒤 8자를 항상 붙인다. 닉네임이 통째로
/// 잘려 나가도 접미사는 남아 이름이 비지 않는다 (빈 이름 역시 `MCPeerID`가 거부한다).
public func makeExchangePeerName(nickname: String, ownerID: String) -> String {
    let suffix = String(ownerID.suffix(8))
    let budget = ExchangeConstants.maximumPeerNameBytes - suffix.utf8.count - 1 // "#"
    var name = ""
    for character in nickname.prefix(ExchangeConstants.maximumPeerNicknameCharacters) {
        guard name.utf8.count + character.utf8.count <= budget else { break }
        name.append(character)
    }
    return "\(name)#\(suffix)"
}
