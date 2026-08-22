import Testing
@testable import Core

@Suite("InterestCatalog")
struct InterestCatalogTests {
    @Test("categories match the complete approved catalog in order")
    func categoriesMatchApprovedCatalog() {
        let expected: [InterestCategory] = [
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

        #expect(InterestCatalog.categories == expected)
        #expect(InterestCatalog.interests == Set(expected.flatMap(\.interests)))
    }

    @Test("approved interest names are unique nonempty nouns")
    func approvedInterestsAreUniqueNonemptyNouns() {
        let interests = InterestCatalog.categories.flatMap(\.interests)

        #expect(interests.count == 28)
        #expect(interests.count == Set(interests).count)
        #expect(interests.allSatisfy { !$0.isEmpty && !$0.hasSuffix("것") })
    }

    /// 겹침 판정은 정확한 문자열 비교다(`CardSnapshot.sharedInterests`). 한 이름이 다른
    /// 이름을 품고 있으면(테크 ⊃ 개발, 취미 생활 ⊃ 게임) 실제로는 같은 관심사인데 겹이
    /// 잡히지 않는다. 3개만 고르는 제약에서 이 손실은 그대로 사용자 경험이 된다.
    @Test("no catalog name contains another")
    func noNameContainsAnother() {
        let interests = InterestCatalog.categories.flatMap(\.interests)

        for name in interests {
            let swallowed = interests.filter { $0 != name && $0.contains(name) }
            #expect(swallowed.isEmpty, "\(name)이(가) \(swallowed)에 포함된다")
        }
    }
}
