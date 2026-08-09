import CardKit
import Core
import DesignSystem
import SwiftUI

/// 카드 상세. 상대 카드면 겹치는 관심사를 하이라이트하고("어, 너도 클라이밍?"),
/// 내 카드면 내 관심사·성향을 카드와 함께 보여준다 (F31).
struct CardDetailView: View {
    let card: CardSnapshot
    let myCard: CardSnapshot?
    @Environment(\.dismiss) private var dismiss

    private var isMyCard: Bool {
        guard let myCard else { return false }
        return myCard.ownerID == card.ownerID
    }

    private var sharedInterests: [String] {
        guard let myCard, !isMyCard else { return [] }
        return card.sharedInterests(with: myCard)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    CardView(card: card)

                    if isMyCard {
                        myInterestsSection
                    } else if !sharedInterests.isEmpty {
                        sharedSection
                    }
                }
                .padding(DS.Spacing.m)
            }
            .background(DS.Palette.background)
            .navigationTitle(card.nickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    // 무채 크롬 — 이 화면의 주인공은 카드다 (U1 원칙 3)
                    Button("닫기") { dismiss() }
                        .tint(.primary)
                }
            }
        }
    }

    /// 내 카드 — 카드 면에는 없는 관심사·성향을 아래에 함께 펼친다 (F31).
    /// 카드는 이모지·이름·한줄평만 담기로 했으므로(F2), 상세가 그 정보를 보완한다.
    private var myInterestsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("나를 이루는 것")
                .font(DS.Typo.title)
            InterestPills(items: card.interests + [card.leisureStyle.label])
            Text("이 선택들이 카드의 색이 됐어요")
                .font(DS.Typo.footnote)
                .foregroundStyle(DS.Palette.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "나를 이루는 것. 관심사 \(card.interests.joined(separator: ", ")). 성향 \(card.leisureStyle.label). 이 선택들이 카드의 색이 됐어요"
        )
    }

    private var sharedSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("겹치는 관심사")
                .font(DS.Typo.title)
            ForEach(sharedInterests, id: \.self) { interest in
                // 겹침 하이라이트는 와인 톤 — 카드가 주인공인 화면이라 크롬이 양보 (U1 원칙 3)
                Label(interest, systemImage: "checkmark.circle.fill")
                    .font(DS.Typo.headline)
                    .foregroundStyle(DS.Palette.overlapInk)
            }
            Text("다음에 만나면 여기서 시작하세요")
                .font(DS.Typo.footnote)
                .foregroundStyle(DS.Palette.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("겹치는 관심사 \(sharedInterests.joined(separator: ", ")). 다음에 만나면 여기서 시작하세요")
    }
}

/// 내 관심사·성향 알약 줄 — 겹침 알약(카드 안)과 구분되도록 무채 표면을 쓴다.
private struct InterestPills: View {
    let items: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), spacing: DS.Spacing.s)],
            spacing: DS.Spacing.s
        ) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(DS.Typo.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.xs)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    .background(DS.Palette.surface, in: Capsule())
            }
        }
    }
}

#Preview("상대 카드") {
    CardDetailView(card: MockData.sampleCards[0], myCard: MockData.sampleCards[2])
}

#Preview("내 카드") {
    CardDetailView(card: MockData.sampleCards[0], myCard: MockData.sampleCards[0])
}
