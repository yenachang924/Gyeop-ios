import Testing
@testable import Core

@Suite("InterestCatalog")
struct InterestCatalogTests {
    @Test("categories match the complete approved catalog in order")
    func categoriesMatchApprovedCatalog() {
        let expected: [InterestCategory] = [
            .init(
                title: "어떤 일을 하고 있나요?",
                interests: ["경영", "테크", "개발", "엔지니어링", "데이터 분석", "서비스 기획", "UX/UI", "디자인", "연구", "AI", "금융"]
            ),
            .init(
                title: "쉴 때는 무엇을 하나요?",
                interests: ["맛집 탐방", "카페", "여행", "사진", "독서", "음악", "영화", "게임", "운동", "취미 생활"]
            ),
            .init(
                title: "어떤 활동으로 사람을 만나나요?",
                interests: ["네트워킹", "사이드 프로젝트", "창업", "커뮤니티", "링크드인", "인스타그램"]
            ),
        ]

        #expect(InterestCatalog.categories == expected)
        #expect(InterestCatalog.interests == Set(expected.flatMap(\.interests)))
    }

    @Test("approved interest names are unique nonempty nouns")
    func approvedInterestsAreUniqueNonemptyNouns() {
        let interests = InterestCatalog.categories.flatMap(\.interests)

        #expect(interests.count == 27)
        #expect(interests.count == Set(interests).count)
        #expect(interests.allSatisfy { !$0.isEmpty && !$0.hasSuffix("것") })
    }
}
