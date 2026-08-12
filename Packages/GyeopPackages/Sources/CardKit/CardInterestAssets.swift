import Foundation

/// 카드 우측 상단에 겹쳐 보이는 관심사 에셋의 결정적 순서.
///
/// 카드가 받은 순서 그대로 아이콘을 쌓아, 같은 카드가 어느 화면에서나 같은 Glass
/// 에셋 배열을 보이게 한다(F76).
public enum CardInterestAssets {
    public static func symbols(for interests: [String]) -> [String] {
        interests.map(InterestSymbol.emoji(for:))
    }
}
