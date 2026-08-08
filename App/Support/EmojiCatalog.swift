import Core
import Foundation

/// 번들 리소스 emoji-icons.csv (원본: docs/assets/emoji-icons.csv)
/// 온보딩의 관심사 선택지와 이모지 원탭 피커가 이 카탈로그 하나를 공유한다.
struct EmojiIcon: Identifiable, Hashable {
    let emoji: String
    let name: String
    let category: String

    var id: String { name }
}

enum EmojiCatalog {
    static let all: [EmojiIcon] = load()

    private static func load() -> [EmojiIcon] {
        guard let url = Bundle.main.url(forResource: "emoji-icons", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            Log.render.error("emoji-icons.csv 번들 로드 실패")
            return []
        }
        return text
            .split(separator: "\n")
            .dropFirst() // 헤더
            .compactMap { line in
                let columns = line.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                guard columns.count == 3 else { return nil }
                return EmojiIcon(emoji: columns[0], name: columns[1], category: columns[2])
            }
    }
}
