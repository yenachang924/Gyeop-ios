import Core
import Foundation
import SwiftUI

/// 카드 시드 규칙의 유일한 정의 지점: **정렬된 관심사 + MBTI 코드 + 닉네임 + 이모지 → sha256**.
/// `ownerID`·`version`은 의도적으로 제외한다 — 시드가 프로필 식별자와 무관해야
/// 아직 `UserProfile`이 만들어지기 전인 온보딩 실시간 프리뷰(`CardPreview`)에서도
/// 최종 저장되는 카드와 동일한 시드·비주얼을 낼 수 있다.
///
/// F55: 성향(LeisureStyle) 자리가 MBTI로 바뀌었다. 건너뛴 사용자는 빈 문자열로
/// 들어간다 — 비워도 시드는 결정적이다.
public enum CardSeed {
    public static func hash(
        nickname: String,
        emoji: String,
        interests: [String],
        mbti: MBTI?
    ) -> String {
        let canonical = [
            interests.sorted().joined(separator: ","),
            mbti?.code ?? "",
            nickname,
            emoji,
        ].joined(separator: "|")
        return DeterministicHash.sha256Hex(canonical)
    }

    public static func hash(for profile: UserProfile) -> String {
        hash(
            nickname: profile.nickname,
            emoji: profile.emoji,
            interests: profile.interests,
            mbti: profile.mbti
        )
    }
}

/// 온보딩 실시간 프리뷰용 경량 API. 관심사·닉네임·이모지 선택이 바뀔 때마다
/// 이 값으로 `CardVisual`을 다시 만들면 된다 — `UserProfile`/`CardSnapshot` 전체를
/// 구성할 필요가 없다. (2/3 유동 프리뷰(F17)는 MBTI 화면(F55)과 함께 은퇴했다 —
/// `QuadrantPalette`도 그때 제거.)
public enum CardPreview {
    public static func visual(
        nickname: String,
        emoji: String,
        interests: [String],
        mbti: MBTI? = nil
    ) -> CardVisual {
        CardVisual(
            seed: CardSeed.hash(nickname: nickname, emoji: emoji, interests: interests, mbti: mbti)
        )
    }
}

/// `CardGenerating`의 실구현. 시드 규칙은 `CardSeed`, 시드 → 비주얼 변환은 `CardVisual`이 맡는다.
public struct CardGenerator: CardGenerating {
    public init() {}

    public func makeCard(from profile: UserProfile, version: Int) -> CardSnapshot {
        CardSnapshot(
            ownerID: profile.id,
            seed: CardSeed.hash(for: profile),
            nickname: profile.nickname,
            tagline: profile.tagline,
            emoji: profile.emoji,
            interests: profile.interests,
            mbti: profile.mbti,
            version: version,
            createdAt: profile.createdAt
        )
    }
}
