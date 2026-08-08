import Core
import DesignSystem
import SwiftUI

/// 정체성 카드 렌더. 앱에서 커스텀 비주얼이 허용된 유일한 컴포넌트 (CLAUDE.md UI 원칙).
///
/// 시드 → 비주얼 결정성 계약은 `CardVisual`에 있다. 질감은 결정 R2에서
/// "그레인 없음"으로 확정 — `cardTexture(_:)`의 항등 변환이 곧 최종 스펙이다.
public struct CardView: View {
    private let card: CardSnapshot

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(card: CardSnapshot) {
        self.card = card
    }

    /// 등간격 제어점 격자 (결정 R2: 5×5). 위치는 고정, 색만 시드가 정한다 —
    /// 위치까지 흔들면 "같은 입력=같은 카드"의 비교 가능성이 흐려진다.
    private static let meshPoints: [SIMD2<Float>] = {
        let n = CardVisual.meshDimension
        return (0..<n).flatMap { row in
            (0..<n).map { column in
                SIMD2(Float(column) / Float(n - 1), Float(row) / Float(n - 1))
            }
        }
    }()

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text(card.emoji)
                .font(DS.Typo.largeTitle)
                .foregroundStyle(.white)
                .accessibilityLabel("\(card.nickname)의 대표 이모지")

            Spacer(minLength: DS.Spacing.l)

            // 배경(MeshGradient)은 흰 텍스트 대비 4.5:1을 보장하도록 생성되므로
            // (CardVisual) 시스템 컬러 대신 고정 흰색을 쓴다 — 다크·라이트 모드 무관.
            Text(card.nickname)
                .font(DS.Typo.title)
                .foregroundStyle(.white)
            Text(card.tagline)
                .font(DS.Typo.body)
                .foregroundStyle(.white)

            interestChips
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 고정 0.7 비율은 콘텐츠(닉네임·태그라인·칩)가 자라는 접근성 폰트 크기에서
        // clipShape에 잘린다 — 접근성 크기에서는 비율을 풀고 세로로 자라게 둔다.
        .aspectRatio(dynamicTypeSize.isAccessibilitySize ? nil : 0.7, contentMode: .fit)
        .background {
            MeshGradient(
                width: CardVisual.meshDimension,
                height: CardVisual.meshDimension,
                points: Self.meshPoints,
                colors: CardVisual(seed: card.seed).colors
            )
            .cardTexture()
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
