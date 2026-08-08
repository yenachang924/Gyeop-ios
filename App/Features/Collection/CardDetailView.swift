import CardKit
import Core
import DesignSystem
import SwiftUI

/// 카드 상세 — 겹치는 관심사 하이라이트 ("어, 너도 클라이밍?")
struct CardDetailView: View {
    let card: CardSnapshot
    let myCard: CardSnapshot?
    @Environment(\.dismiss) private var dismiss

    private var sharedInterests: [String] {
        guard let myCard, myCard.ownerID != card.ownerID else { return [] }
        return card.sharedInterests(with: myCard)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    CardView(card: card)

                    if !sharedInterests.isEmpty {
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
                                .font(DS.Typo.caption)
                                .foregroundStyle(DS.Palette.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("겹치는 관심사 \(sharedInterests.joined(separator: ", ")). 다음에 만나면 여기서 시작하세요")
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
}

#Preview {
    CardDetailView(card: MockData.sampleCards[0], myCard: MockData.sampleCards[2])
}
