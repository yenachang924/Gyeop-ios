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

    @Test("제어점은 9개, 색상 각도는 전부 0...1 범위")
    func controlPointCount() {
        let visual = CardVisual(seed: MockData.sampleCards[0].seed)
        #expect(visual.controlPoints.count == 9)
        #expect(visual.controlPoints.allSatisfy { (0.0...1.0).contains($0.hue) })
    }
}

@Suite("CardVisual — 채도 70~80%·명도 45~62% 범위")
struct CardVisualRangeTests {
    @Test("모든 제어점의 채도·명도가 지정 범위 안에 있다")
    func hsbRanges() {
        for index in 0..<50 {
            let visual = CardVisual(
                seed: CardSeed.hash(
                    nickname: "러너\(index)",
                    emoji: "✨",
                    interests: ["관심사\(index)"],
                    leisureStyle: LeisureStyle(
                        energy: index.isMultiple(of: 2) ? .calm : .active,
                        venue: index.isMultiple(of: 3) ? .indoor : .outdoor
                    )
                )
            )
            for point in visual.controlPoints {
                #expect(CardVisual.saturationRange.contains(point.saturation))
                // 명도는 대비 보정으로 하한 밑까지 낮아질 수 있어 상한만 검증한다.
                #expect(point.brightness <= CardVisual.brightnessRange.upperBound)
                #expect(point.brightness >= 0)
            }
        }
    }
}

@Suite("CardVisual — 흰 텍스트 대비 4.5:1")
struct CardVisualContrastTests {
    @Test("100개 랜덤 시드 스냅샷에서 모든 제어점이 흰 텍스트 대비 4.5:1 이상")
    func contrastAcrossManySeeds() {
        let interestPool = ["클라이밍", "보드게임", "커피", "사진", "여행", "독서", "요리", "러닝", "음악", "영화"]
        let emojiPool = ["🧗", "🎲", "☕️", "📷", "✈️", "📚", "🍳", "🏃", "🎵", "🎬"]

        for index in 0..<100 {
            let seed = CardSeed.hash(
                nickname: "러너\(index)",
                emoji: emojiPool[index % emojiPool.count],
                interests: [
                    interestPool[index % interestPool.count],
                    interestPool[(index * 7 + 3) % interestPool.count],
                ],
                leisureStyle: LeisureStyle(
                    energy: index.isMultiple(of: 2) ? .calm : .active,
                    venue: index.isMultiple(of: 3) ? .indoor : .outdoor
                )
            )
            let visual = CardVisual(seed: seed)
            for point in visual.controlPoints {
                let contrast = CardVisual.contrastAgainstWhite(
                    hue: point.hue, saturation: point.saturation, brightness: point.brightness
                )
                #expect(contrast >= CardVisual.minimumWhiteContrast)
            }
        }
    }
}

@Suite("CardSeed / CardPreview / CardGenerator")
struct CardSeedTests {
    @Test("관심사 순서가 달라도 같은 시드(정렬 후 해시)")
    func interestOrderIsIrrelevant() {
        let a = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["커피", "보드게임", "클라이밍"],
            leisureStyle: LeisureStyle(energy: .active, venue: .indoor)
        )
        let b = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["클라이밍", "커피", "보드게임"],
            leisureStyle: LeisureStyle(energy: .active, venue: .indoor)
        )
        #expect(a == b)
    }

    @Test("닉네임이 다르면 다른 시드")
    func differentNicknameDifferentSeed() {
        let a = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["커피"],
            leisureStyle: LeisureStyle(energy: .active, venue: .indoor)
        )
        let b = CardSeed.hash(
            nickname: "도윤", emoji: "🧗", interests: ["커피"],
            leisureStyle: LeisureStyle(energy: .active, venue: .indoor)
        )
        #expect(a != b)
    }

    @Test("실시간 프리뷰(CardPreview)와 최종 CardGenerator가 같은 비주얼을 낸다")
    func previewMatchesGenerator() {
        let profile = MockData.sampleProfiles[0]
        let previewVisual = CardPreview.visual(
            nickname: profile.nickname,
            emoji: profile.emoji,
            interests: profile.interests,
            leisureStyle: profile.leisureStyle
        )
        let generated = CardGenerator().makeCard(from: profile)
        #expect(previewVisual == CardVisual(seed: generated.seed))
    }

    @Test("같은 프로필 = 항상 같은 카드 시드")
    func deterministicGeneration() {
        let generator = CardGenerator()
        let profile = MockData.sampleProfiles[0]
        #expect(generator.makeCard(from: profile).seed == generator.makeCard(from: profile).seed)
    }

    @Test("관심사가 바뀌면 시드도 바뀐다")
    func changedInterestsChangeSeed() {
        let generator = CardGenerator()
        var profile = MockData.sampleProfiles[0]
        let before = generator.makeCard(from: profile).seed
        profile.interests.append("새관심사")
        let after = generator.makeCard(from: profile).seed
        #expect(before != after)
    }
}

#if canImport(UIKit)
@Suite("CardImageExporter")
struct CardImageExporterTests {
    @Test("카드를 PNG 데이터로 내보낼 수 있다")
    @MainActor
    func exportsPNGData() {
        let data = CardImageExporter.renderPNGData(for: MockData.sampleCards[0])
        #expect(data != nil)
        #expect((data?.count ?? 0) > 0)
    }
}
#endif
