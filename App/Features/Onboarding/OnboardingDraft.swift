import Core

/// 온보딩 3단계가 공유하는 입력 초안. 본앱(OnboardingFlowView)과 클립
/// (ClipOnboardingFlowView — GyeopClip 타깃이 이 파일과 3단계 뷰를 소스 공유)이 함께 쓴다.
struct OnboardingDraft {
    var interests: [String] = []
    /// MBTI — 건너뛰면 nil (F55).
    var mbti: MBTI?
    var nickname = ""
    var tagline = ""
    var emoji = ""
}
