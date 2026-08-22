public struct InterestCategory: Equatable, Sendable, Identifiable {
    public let title: String
    public let interests: [String]

    public var id: String { title }

    public init(title: String, interests: [String]) {
        self.title = title
        self.interests = interests
    }
}

public enum InterestCatalog {
    public static let categories: [InterestCategory] = [
        // 머리말은 묻는 말이 아니라 관심사의 갈래 이름이다 (소유자 지시). 질문으로 세우면
        // 직업·활동을 캐묻는 설문처럼 읽혀 "요즘 나를 이루는 것"에서 멀어진다.
        //
        // 첫 갈래는 직무 목록이 아니라 **일·배움 쪽 관심사**다. 개발·AI·데이터 분석처럼
        // IT 직군 이름을 늘어놓으면 그 바닥 사람만 쓰는 앱처럼 읽힌다.
        .init(
            title: "일과 배움",
            interests: ["창업", "마케팅", "디자인", "테크", "투자", "교육", "글쓰기", "외국어", "자기계발", "연구"]
        ),
        .init(
            title: "취향과 일상",
            interests: ["맛집 탐방", "카페", "여행", "요리", "사진", "독서", "음악", "영화", "게임", "운동", "패션", "반려동물"]
        ),
        .init(
            title: "사람과 활동",
            interests: ["네트워킹", "사이드 프로젝트", "스터디", "봉사", "공연 관람", "스포츠 관람"]
        ),
    ]

    public static let interests: Set<String> = Set(categories.flatMap(\.interests))

    public static func sanitizedSelection(from legacyInterests: [String]) -> [String] {
        legacyInterests.reduce(into: [String]()) { sanitized, interest in
            guard sanitized.count < ProfileInput.interestCount,
                  interests.contains(interest),
                  !sanitized.contains(interest)
            else { return }
            sanitized.append(interest)
        }
    }
}
