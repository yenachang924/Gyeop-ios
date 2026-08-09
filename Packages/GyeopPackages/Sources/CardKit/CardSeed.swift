import Core
import Foundation
import SwiftUI

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

    /// 2/3 유동 프리뷰 (F17): 성향 2축 연속값(0~1)이 카드 색에 연속적으로 기여한다.
    /// 4분면 시드 각각의 제어점 색을 이중선형 보간 — 축이 사분면 경계를 지나도 색이
    /// 끊기지 않고 흐른다. 저장되는 최종 카드는 양자화된 `LeisureStyle` 시드를 그대로
    /// 쓰므로 "같은 입력=같은 카드"의 결정성은 유지된다.
    /// 4분면 팔레트를 **한 번만** 만들어 들고 있다가, 축 값이 바뀔 때는 보간만 한다 (F49).
    ///
    /// 이전에는 슬라이더를 끄는 **매 프레임** 4개의 `CardVisual`을 새로 만들었다 —
    /// sha256 4회 + 색마다 대비 보정 루프까지 돌아 드래그가 뚝뚝 끊겼다.
    /// 팔레트는 이름·이모지·관심사에만 의존하므로 그 값이 바뀔 때만 다시 만들면 된다.
    public struct QuadrantPalette: Sendable {
        private let calmIndoor: [Color]
        private let calmOutdoor: [Color]
        private let activeIndoor: [Color]
        private let activeOutdoor: [Color]

        public init(nickname: String, emoji: String, interests: [String]) {
            func quadrant(_ e: LeisureStyle.Energy, _ v: LeisureStyle.Venue) -> [Color] {
                CardPreview.visual(
                    nickname: nickname, emoji: emoji, interests: interests,
                    leisureStyle: LeisureStyle(energy: e, venue: v)
                ).colors
            }
            calmIndoor = quadrant(.calm, .indoor)
            calmOutdoor = quadrant(.calm, .outdoor)
            activeIndoor = quadrant(.active, .indoor)
            activeOutdoor = quadrant(.active, .outdoor)
        }

        /// 두 축(0~1)의 이중선형 보간 — 프레임마다 불려도 색 섞기뿐이라 가볍다.
        public func colors(energy: Double, venue: Double) -> [Color] {
            let e = min(max(energy, 0), 1)
            let v = min(max(venue, 0), 1)
            return calmIndoor.indices.map { index in
                let calm = calmIndoor[index].mix(with: calmOutdoor[index], by: v)
                let active = activeIndoor[index].mix(with: activeOutdoor[index], by: v)
                return calm.mix(with: active, by: e)
            }
        }
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
