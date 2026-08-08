import CardKit
import Core
import DesignSystem
import SwiftUI

/// 컬렉션 — 내 카드 + 겹에서 받은 카드들. 수료 D-day가 상단에 흐른다 (시즌 시계).
struct CollectionView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedCard: CardSnapshot?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    seasonHeader

                    if let myCard = model.myCard {
                        myCardSection(myCard)
                    }

                    collectedSection
                }
                .padding(DS.Spacing.m)
            }
            .background(DS.Palette.background)
            .navigationTitle("컬렉션")
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, myCard: model.myCard)
            }
        }
    }

    private var seasonHeader: some View {
        let dDay = model.season.daysRemaining(from: .now)
        return HStack(spacing: DS.Spacing.s) {
            Text("수료까지 D-\(dDay)")
                .font(DS.Typo.headline)
            Spacer()
            Text("겹 \(model.gyeops.count)회")
                .font(DS.Typo.headline)
                .foregroundStyle(DS.Palette.accent)
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.surface, in: RoundedRectangle(cornerRadius: DS.Radius.chip))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("수료까지 \(dDay)일, 겹 \(model.gyeops.count)회")
    }

    private func myCardSection(_ card: CardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("내 카드")
                .font(DS.Typo.title)
            Button {
                selectedCard = card
            } label: {
                CardView(card: card)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("collection.myCard")
        }
    }

    private var collectedSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("받은 카드")
                .font(DS.Typo.title)

            if model.gyeops.isEmpty {
                ContentUnavailableView(
                    "아직 겹이 없어요",
                    systemImage: "person.2",
                    description: Text("옆 러너와 아이폰을 맞대보세요 — 그게 전부입니다")
                )
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: DS.Spacing.s)],
                    spacing: DS.Spacing.s
                ) {
                    ForEach(model.gyeops) { gyeop in
                        Button {
                            selectedCard = gyeop.counterpartCard
                        } label: {
                            CardView(card: gyeop.counterpartCard)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("collection.card.\(gyeop.counterpartCard.nickname)")
                    }
                }
            }
        }
    }
}

#Preview {
    CollectionView()
        .environment(
            AppModel(
                cardGenerator: MockCardGenerator(),
                repository: MockGyeopRepository(seededGyeops: MockData.sampleGyeops)
            )
        )
}
