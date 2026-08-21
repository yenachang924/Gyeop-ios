import Core

/// 온보딩 3단계가 공유하는 불변 입력 초안.
struct OnboardingDraft {
    let interests: [String]
    /// MBTI를 건너뛰면 nil (F55).
    let mbti: MBTI?
    let nickname: String
    let currentStatus: String
    let emoji: String

    static let empty = OnboardingDraft()

    init(
        interests: [String] = [],
        mbti: MBTI? = nil,
        nickname: String = "",
        currentStatus: String = "",
        emoji: String = ""
    ) {
        self.interests = interests
        self.mbti = mbti
        self.nickname = nickname
        self.currentStatus = currentStatus
        self.emoji = emoji
    }

    init(editing profile: UserProfile) {
        self.init(
            interests: InterestCatalog.sanitizedSelection(from: profile.interests),
            mbti: profile.mbti,
            nickname: profile.nickname,
            currentStatus: profile.currentStatus,
            emoji: profile.emoji
        )
    }

    func replacing(interests: [String]) -> Self {
        OnboardingDraft(
            interests: interests,
            mbti: mbti,
            nickname: nickname,
            currentStatus: currentStatus,
            emoji: emoji
        )
    }

    func replacing(mbti: MBTI?) -> Self {
        OnboardingDraft(
            interests: interests,
            mbti: mbti,
            nickname: nickname,
            currentStatus: currentStatus,
            emoji: emoji
        )
    }

    func replacing(nickname: String) -> Self {
        OnboardingDraft(
            interests: interests,
            mbti: mbti,
            nickname: nickname,
            currentStatus: currentStatus,
            emoji: emoji
        )
    }

    func replacing(currentStatus: String) -> Self {
        OnboardingDraft(
            interests: interests,
            mbti: mbti,
            nickname: nickname,
            currentStatus: currentStatus,
            emoji: emoji
        )
    }

    func replacing(emoji: String) -> Self {
        OnboardingDraft(
            interests: interests,
            mbti: mbti,
            nickname: nickname,
            currentStatus: currentStatus,
            emoji: emoji
        )
    }
}
