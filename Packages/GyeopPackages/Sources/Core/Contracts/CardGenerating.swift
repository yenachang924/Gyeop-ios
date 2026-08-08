import Foundation

/// 프로필 → 카드 스냅샷. **결정적이어야 한다**: 같은 프로필 입력이면 언제나 같은 시드.
///
/// 소유: CardKit 세션이 실구현(시드 → MeshGradient + Metal 셰이더)을 제공한다.
/// 다른 세션은 `MockCardGenerator`로 개발한다.
public protocol CardGenerating: Sendable {
    /// - Parameter version: 카드 버전. 관심사 변경 시 호출부가 올려서 넘긴다.
    func makeCard(from profile: UserProfile, version: Int) -> CardSnapshot
}

extension CardGenerating {
    public func makeCard(from profile: UserProfile) -> CardSnapshot {
        makeCard(from: profile, version: 1)
    }
}
