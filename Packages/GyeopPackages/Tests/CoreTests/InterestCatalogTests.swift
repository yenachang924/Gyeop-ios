import Testing
@testable import Core

@Suite("InterestCatalog")
struct InterestCatalogTests {
    @Test("categories have approved titles and unique noun-form interests")
    func categoriesAreUnique() {
        let categories = InterestCatalog.categories
        let interests = categories.flatMap(\.interests)

        #expect(categories.map(\.title) == ["일과 기술", "취향과 일상", "모임과 활동"])
        #expect(interests.count == 27)
        #expect(interests.count == Set(interests).count)
        #expect(interests.allSatisfy { !$0.isEmpty && !$0.hasSuffix("것") })
    }

    @Test("membership is derived from all categories")
    func membershipContainsEveryCatalogInterest() {
        let interests = InterestCatalog.categories.flatMap(\.interests)

        #expect(InterestCatalog.interests == Set(interests))
    }
}
