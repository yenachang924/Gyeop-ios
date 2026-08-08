import Core
import DesignSystem
import SwiftUI

/// 정체성 카드 렌더. 앱에서 커스텀 비주얼이 허용된 유일한 컴포넌트 (CLAUDE.md UI 원칙).
///
/// 현재는 시드 기반 MeshGradient까지 — Metal `layerEffect` 질감·60fps 검증은
/// CardKit 소유 세션이 이어받는다. 시드 → 비주얼 결정성 계약은 `CardVisual`에 있다.
public struct CardView: View {
    private let card: CardSnapshot
    @Environment(\.colorScheme) private var colorScheme

    public init(card: CardSnapshot) {
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text(card.emoji)
                .font(DS.Typo.largeTitle)
                .accessibilityLabel("\(card.nickname)의 대표 이모지")

            Spacer(minLength: DS.Spacing.l)

            Text(card.nickname)
                .font(DS.Typo.title)
            Text(card.tagline)
                .font(DS.Typo.body)

            interestChips
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(0.7, contentMode: .fit)
        .background {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1],
                ],
                colors: CardVisual(seed: card.seed).meshColors(scheme: colorScheme)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(card.nickname)의 카드. \(card.tagline). 관심사 \(card.interests.joined(separator: ", ")). 성향 \(card.leisureStyle.label)"
        )
    }

    private var interestChips: some View {
        FlowingChips(items: card.interests + [card.leisureStyle.label])
    }
}

/// 카드 안 관심사 칩 (단순 가로 랩 — 카드 폭 기준 한 줄 유지가 안 되면 줄바꿈은 시스템에 맡긴다)
struct FlowingChips: View {
    let items: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chipRow(items)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                chipRow(Array(items.prefix(3)))
                chipRow(Array(items.dropFirst(3)))
            }
        }
    }

    private func chipRow(_ row: [String]) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(row, id: \.self) { item in
                Text(item)
                    .font(DS.Typo.caption)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }
}

#Preview("샘플 카드") {
    CardView(card: MockData.sampleCards[0])
        .padding()
}
