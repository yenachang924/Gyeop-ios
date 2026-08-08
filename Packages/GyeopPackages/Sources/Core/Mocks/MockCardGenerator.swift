import Foundation

/// 결정적 목업 카드 생성기. 실구현(CardKit의 셰이더 시드 함수)이 오기 전까지의 접점.
/// 시드 규칙: 프로필의 정규화 문자열 → sha256. 같은 입력 = 같은 시드가 계약의 전부다.
public struct MockCardGenerator: CardGenerating {
    public init() {}

    public func makeCard(from profile: UserProfile, version: Int) -> CardSnapshot {
        let canonical = [
            profile.id,
            profile.nickname,
            profile.emoji,
            profile.interests.sorted().joined(separator: ","),
            profile.leisureStyle.energy.rawValue,
            profile.leisureStyle.venue.rawValue,
            "v\(version)",
        ].joined(separator: "|")

        return CardSnapshot(
            ownerID: profile.id,
            seed: DeterministicHash.sha256Hex(canonical),
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
