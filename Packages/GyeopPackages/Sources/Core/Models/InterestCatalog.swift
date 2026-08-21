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
        .init(
            title: "일과 기술",
            interests: ["경영", "테크", "개발", "엔지니어링", "데이터 분석", "서비스 기획", "UX/UI", "디자인", "연구", "AI", "금융"]
        ),
        .init(
            title: "취향과 일상",
            interests: ["맛집 탐방", "카페", "여행", "사진", "독서", "음악", "영화", "게임", "운동", "취미 생활"]
        ),
        .init(
            title: "모임과 활동",
            interests: ["네트워킹", "사이드 프로젝트", "창업", "커뮤니티", "링크드인", "인스타그램"]
        ),
    ]

    public static let interests: Set<String> = Set(categories.flatMap(\.interests))
}
