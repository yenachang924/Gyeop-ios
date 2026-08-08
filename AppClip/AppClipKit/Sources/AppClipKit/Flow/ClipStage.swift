import Core
import Foundation

/// 클립 플로우 단계. AppModel.Stage(App)와 같은 자리지만 클립은 계정이 없고
/// 카드 수신→온보딩→교환→설치 제안으로 끝나는 짧은 선형 플로우다.
public enum ClipStage: Sendable, Equatable {
    /// 인보케이션 URL 대기/파싱 직후
    case invocation
    /// 빠른 프로필 입력 → 내 카드 생성
    case onboarding
    /// ExchangeSession 진행 중 (탐색→발견→연결→수신)
    case exchanging
    /// 겹 성립 — **교환이 끝난 뒤에만** 여기서 설치를 제안한다 (제품의 핵심 주장)
    case suggestingInstall(GyeopRecord)
    case failed(ExchangeFailure)
}
