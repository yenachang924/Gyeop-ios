import Foundation

/// 클립 인보케이션 URL(링크 탭 또는 QR 스캔)에서 파싱한 초대 정보.
/// 두 진입 경로(링크·QR) 모두 같은 URL 스킴으로 수렴하므로 파서는 하나다.
public struct ClipInvocation: Sendable, Equatable {
    /// 상대가 브로드캐스트 중인 교환을 식별하는 토큰 — ExchangeSession Mock 배선의 입력이 된다.
    public let exchangeToken: String
    /// 초대장에 실린 상대 닉네임 (있으면 온보딩 전에 "OO님이 카드를 건넸어요" 같은 문구에 쓴다)
    public let inviterNickname: String?

    public init(exchangeToken: String, inviterNickname: String? = nil) {
        self.exchangeToken = exchangeToken
        self.inviterNickname = inviterNickname
    }
}
