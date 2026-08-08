import Foundation

/// 클립 전용 축약 관심사·이모지 카탈로그.
///
/// App의 `EmojiCatalog`(App/Support, 25항목 CSV 번들)는 App 타깃 전용 파일이라 클립이
/// 참조할 수 없다 — 공용 패키지로 옮겨지기 전까지는 진짜 "공용 뷰 재사용"이 불가능한 구조적
/// 갭이다 (AppClip/README.md 참고). 클립은 번들 리소스 로드 없이 즉시 뜨는 게 우선이라
/// 같은 데이터에서 가장 자주 쓰이는 12개만 하드코딩해 들고 다닌다.
public struct ClipInterest: Identifiable, Hashable, Sendable {
    public let emoji: String
    public let name: String

    public var id: String { name }

    public init(emoji: String, name: String) {
        self.emoji = emoji
        self.name = name
    }
}

public enum ClipInterestCatalog {
    public static let all: [ClipInterest] = [
        ClipInterest(emoji: "🧗", name: "클라이밍"),
        ClipInterest(emoji: "🎲", name: "보드게임"),
        ClipInterest(emoji: "🏃", name: "러닝"),
        ClipInterest(emoji: "📷", name: "사진"),
        ClipInterest(emoji: "☕", name: "커피"),
        ClipInterest(emoji: "🎸", name: "음악"),
        ClipInterest(emoji: "🎬", name: "영화"),
        ClipInterest(emoji: "📚", name: "독서"),
        ClipInterest(emoji: "🍳", name: "요리"),
        ClipInterest(emoji: "🎮", name: "게임"),
        ClipInterest(emoji: "⛰️", name: "등산"),
        ClipInterest(emoji: "🌅", name: "여행"),
    ]
}
