import Core
import Foundation

/// 카드 시드 규칙의 유일한 정의 지점: **정렬된 관심사 + 성향 + 닉네임 + 이모지 → sha256**.
/// `ownerID`·`version`은 의도적으로 제외한다 — 시드가 프로필 식별자와 무관해야
/// 아직 `UserProfile`이 만들어지기 전인 온보딩 실시간 프리뷰(`CardPreview`)에서도
/// 최종 저장되는 카드와 동일한 시드·비주얼을 낼 수 있다.
public enum CardSeed {
    public static func hash(
        nickname: String,
        emoji: String,
        interests: [String],
        leisureStyle: LeisureStyle
    ) -> String {
        let canonical = [
            interests.sorted().joined(separator: ","),
            leisureStyle.energy.rawValue,
            leisureStyle.venue.rawValue,
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
            leisureStyle: profile.leisureStyle
        )
    }
}

/// 온보딩 실시간 프리뷰용 경량 API. 관심사·성향·닉네임·이모지 선택이 바뀔 때마다
/// 이 값으로 `CardVisual`을 다시 만들면 된다 — `UserProfile`/`CardSnapshot` 전체를
/// 구성할 필요가 없다.
public enum CardPreview {
    public static func visual(
        nickname: String,
        emoji: String,
        interests: [String],
        leisureStyle: LeisureStyle
    ) -> CardVisual {
        CardVisual(
            seed: CardSeed.hash(
                nickname: nickname, emoji: emoji, interests: interests, leisureStyle: leisureStyle
            )
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
            leisureStyle: profile.leisureStyle,
            version: version,
            createdAt: profile.createdAt
        )
    }
}
