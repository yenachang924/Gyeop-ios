import Core
import Foundation

/// 번들 리소스 emoji-icons.csv (원본: docs/assets/emoji-icons.csv, 138행)
/// 온보딩의 관심사 선택지와 이모지 원탭 피커가 이 카탈로그 하나를 공유한다.
struct EmojiIcon: Identifiable, Hashable {
    let emoji: String
    let name: String
    let category: String
    let keywords: [String]

    var id: String { name }

    /// 이름·키워드·이모지 자체 어디든 포함되면 검색 일치로 본다 (대소문자 무시).
    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        if name.localizedStandardContains(query) || emoji == query { return true }
        return keywords.contains { $0.localizedStandardContains(query) }
    }
}

enum EmojiCatalog {
    /// 검색 전, 그리드에 1차로 노출하는 개수 — 카탈로그 순서 그대로(결정적).
    static let initialDisplayCount = 16

    static let all: [EmojiIcon] = load()

    /// 카탈로그에 등장하는 순서대로의 카테고리 목록 (F45 카테고리 피커).
    /// CSV 순서를 그대로 따르므로 결정적이다 — 정렬하지 않는다.
    static let categories: [String] = {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }()

    /// 해당 카테고리의 이모지 (카탈로그 순서 유지).
    static func icons(in category: String) -> [EmojiIcon] {
        all.filter { $0.category == category }
    }

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
                guard columns.count == 4 else { return nil }
                let keywords = columns[3].split(separator: ";").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                return EmojiIcon(emoji: columns[0], name: columns[1], category: columns[2], keywords: keywords)
            }
    }
}
