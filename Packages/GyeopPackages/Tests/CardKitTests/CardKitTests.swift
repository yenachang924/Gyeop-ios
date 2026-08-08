import Core
import Testing
@testable import CardKit

@Suite("CardVisual — 시드 결정성")
struct CardVisualTests {
    @Test("같은 시드 = 같은 비주얼 파라미터")
    func deterministicVisual() {
        let seed = MockData.sampleCards[0].seed
        #expect(CardVisual(seed: seed) == CardVisual(seed: seed))
    }

    @Test("다른 시드 = 다른 비주얼 파라미터")
    func differentSeeds() {
        #expect(
            CardVisual(seed: MockData.sampleCards[0].seed)
                != CardVisual(seed: MockData.sampleCards[1].seed)
        )
    }

    @Test("색상 각도는 9개, 전부 0...1 범위")
    func hueRange() {
        let visual = CardVisual(seed: MockData.sampleCards[0].seed)
        #expect(visual.hues.count == 9)
        #expect(visual.hues.allSatisfy { (0.0...1.0).contains($0) })
    }
}
