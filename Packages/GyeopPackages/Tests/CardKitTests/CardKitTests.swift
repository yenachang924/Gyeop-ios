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

    @Test("제어점은 5×5=25개, 색상 각도는 전부 0...1 범위")
    func controlPointCount() {
        let visual = CardVisual(seed: MockData.sampleCards[0].seed)
        #expect(CardVisual.controlPointCount == CardVisual.meshDimension * CardVisual.meshDimension)
        #expect(visual.controlPoints.count == 25)
        #expect(visual.controlPoints.allSatisfy { (0.0...1.0).contains($0.hue) })
    }
}

@Suite("CardVisual — F72 리본 변주")
struct CardVisualRibbonTests {
    @Test("같은 시드는 같은 리본 파라미터를 만들고, 여러 시드는 변주를 만든다")
    func ribbonParametersAreDeterministicAndVaried() {
        let seeds = [
            CardSeed.hash(nickname: "예나", emoji: "🏃", interests: ["달리기", "보드게임"], mbti: MBTI(code: "ENFP")),
            CardSeed.hash(nickname: "민지", emoji: "🎨", interests: ["그림", "사진"], mbti: MBTI(code: "ISFJ")),
            CardSeed.hash(nickname: "하람", emoji: "🧗", interests: ["클라이밍", "캠핑"], mbti: MBTI(code: "ESTP")),
            CardSeed.hash(nickname: "도윤", emoji: "🎸", interests: ["기타", "영화"], mbti: MBTI(code: "INTJ")),
        ]

        let parameters = seeds.map { CardVisual(seed: $0).ribbonParameters }
        for (seed, parameter) in zip(seeds, parameters) {
            #expect(CardVisual(seed: seed).ribbonParameters == parameter)
        }
        #expect(parameters[0] != parameters[1] || parameters[1] != parameters[2] || parameters[2] != parameters[3])
    }

    @Test("교차하는 두 리본은 서로 다른 앵커를 사용한다")
    func ribbonAnchorsAreDistinct() {
        for index in 0..<100 {
            let seed = CardSeed.hash(
                nickname: "리본\(index)", emoji: "✨", interests: ["관심사\(index)"],
                mbti: MBTI(code: index.isMultiple(of: 2) ? "ENFP" : "ISTJ")
            )
            let parameters = CardVisual(seed: seed).ribbonParameters
            #expect(parameters.firstAnchorIndex != parameters.secondAnchorIndex)
        }
    }
}

@Suite("CardVisual — 오라 파스텔 대역 (F56: 채도 25~45%·명도 82~96%)")
struct CardVisualRangeTests {
    @Test("모든 제어점의 채도·명도가 오라 대역 안에 있다")
    func hsbRanges() {
        for index in 0..<50 {
            let visual = CardVisual(
                seed: CardSeed.hash(
                    nickname: "러너\(index)",
                    emoji: "✨",
                    interests: ["관심사\(index)"],
                    mbti: MBTI(code: index.isMultiple(of: 2) ? "INTJ" : "ESFP")
                )
            )
            for point in visual.controlPoints {
                // 채도는 대비 보정으로 하한 밑까지 옅어질 수 있어 상한만 검증한다.
                #expect(point.saturation <= CardVisual.saturationRange.upperBound)
                #expect(point.saturation >= 0)
                // 명도는 대비 보정으로 상한 위(천장까지)로 올라갈 수 있다.
                #expect(point.brightness >= CardVisual.brightnessRange.lowerBound)
                #expect(point.brightness <= CardVisual.brightnessCeiling)
            }
        }
    }
}

@Suite("CardVisual — 잉크 텍스트 대비 4.5:1 (F56: 흰 텍스트 기준에서 반전)")
struct CardVisualContrastTests {
    @Test("100개 랜덤 시드 스냅샷에서 모든 제어점이 잉크 대비 4.5:1 이상")
    func contrastAcrossManySeeds() {
        let interestPool = ["클라이밍", "보드게임", "커피", "사진", "여행", "독서", "요리", "러닝", "음악", "영화"]
        let emojiPool = ["🧗", "🎲", "☕️", "📷", "✈️", "📚", "🍳", "🏃", "🎵", "🎬"]
        let mbtiPool = ["INTJ", "ENFP", "ISFJ", "ESTP", ""]

        for index in 0..<100 {
            let seed = CardSeed.hash(
                nickname: "러너\(index)",
                emoji: emojiPool[index % emojiPool.count],
                interests: [
                    interestPool[index % interestPool.count],
                    interestPool[(index * 7 + 3) % interestPool.count],
                ],
                mbti: MBTI(code: mbtiPool[index % mbtiPool.count])
            )
            let visual = CardVisual(seed: seed)
            for point in visual.controlPoints {
                let contrast = CardVisual.contrastAgainstInk(
                    hue: point.hue, saturation: point.saturation, brightness: point.brightness
                )
                #expect(contrast >= CardVisual.minimumInkContrast)
            }
        }
    }
}

@Suite("MBTI 코드")
struct MBTICodeTests {
    @Test("코드 왕복: 파싱 → code가 원래 문자열")
    func roundTrip() {
        for code in ["INTJ", "ENFP", "istp", "ESFJ"] {
            #expect(MBTI(code: code)?.code == code.uppercased())
        }
    }

    @Test("형식이 어긋난 코드는 nil")
    func invalidCodes() {
        for code in ["", "INT", "INTJX", "ABCD", "EEEE"] {
            #expect(MBTI(code: code) == nil)
        }
    }
}

@Suite("CardSeed / CardPreview / CardGenerator")
struct CardSeedTests {
    @Test("관심사 순서가 달라도 같은 시드(정렬 후 해시)")
    func interestOrderIsIrrelevant() {
        let a = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["커피", "보드게임", "클라이밍"],
            mbti: MBTI(code: "ESTP")
        )
        let b = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["클라이밍", "커피", "보드게임"],
            mbti: MBTI(code: "ESTP")
        )
        #expect(a == b)
    }

    @Test("닉네임이 다르면 다른 시드")
    func differentNicknameDifferentSeed() {
        let a = CardSeed.hash(nickname: "하람", emoji: "🧗", interests: ["커피"], mbti: nil)
        let b = CardSeed.hash(nickname: "도윤", emoji: "🧗", interests: ["커피"], mbti: nil)
        #expect(a != b)
    }

    @Test("MBTI가 다르면 다른 시드, 건너뛴(nil) 경우도 결정적")
    func mbtiAffectsSeed() {
        let skipped = CardSeed.hash(nickname: "하람", emoji: "🧗", interests: ["커피"], mbti: nil)
        #expect(
            skipped == CardSeed.hash(nickname: "하람", emoji: "🧗", interests: ["커피"], mbti: nil)
        )
        let intj = CardSeed.hash(
            nickname: "하람", emoji: "🧗", interests: ["커피"], mbti: MBTI(code: "INTJ")
        )
        #expect(skipped != intj)
    }

    @Test("실시간 프리뷰(CardPreview)와 최종 CardGenerator가 같은 비주얼을 낸다")
    func previewMatchesGenerator() {
        let profile = MockData.sampleProfiles[0]
        let previewVisual = CardPreview.visual(
            nickname: profile.nickname,
            emoji: profile.emoji,
            interests: profile.interests,
            mbti: profile.mbti
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

    @Test("이모지를 비워도 시드는 결정적이고, 채운 경우와는 다른 시드다")
    func emptyEmojiIsDeterministicAndDistinct() {
        let withoutEmoji = CardSeed.hash(nickname: "", emoji: "", interests: [], mbti: nil)
        #expect(withoutEmoji == CardSeed.hash(nickname: "", emoji: "", interests: [], mbti: nil))

        let withEmoji = CardSeed.hash(nickname: "", emoji: "🧗", interests: [], mbti: nil)
        #expect(withoutEmoji != withEmoji)

        // 빈 시드도 카드 비주얼 계약(오라 대역)을 그대로 만족해야 한다.
        let visual = CardVisual(seed: withoutEmoji)
        for point in visual.controlPoints {
            #expect(point.saturation <= CardVisual.saturationRange.upperBound)
            #expect(point.brightness >= CardVisual.brightnessRange.lowerBound)
        }
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
