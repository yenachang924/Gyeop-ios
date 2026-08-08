import CardKit
import Core
import DesignSystem
import SwiftUI

/// 컬렉션 — 내 카드 + 겹에서 받은 카드들.
struct CollectionView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedCard: CardSnapshot?
    @State private var showingExchange = false
    @State private var showingSettings = false
    /// 컬렉션 ↔ 카드 상세 줌 전환 — 시스템 zoom 전환이 matchedGeometry 페어링을 대신한다.
    @Namespace private var cardZoom

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    if let myCard = model.myCard {
                        myCardSection(myCard)
                    }

                    collectedSection
                }
                .padding(DS.Spacing.m)
            }
            .background(DS.Palette.background)
            .navigationTitle("컬렉션")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("설정", systemImage: "gearshape")
                    }
                    // 무채 크롬 — 이 화면의 빨강은 주인공 액션(맞대기) 하나뿐 (U1 원칙 1)
                    .tint(.primary)
                    .accessibilityIdentifier("collection.settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingExchange = true
                    } label: {
                        Label("맞대기", systemImage: "person.line.dotted.person.fill")
                    }
                    .accessibilityIdentifier("collection.exchange")
                }
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, myCard: model.myCard)
                    .navigationTransition(.zoom(sourceID: card.id, in: cardZoom))
            }
            .sheet(isPresented: $showingExchange, onDismiss: {
                Task { await model.enterCollection() }
            }) {
                ExchangeView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
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
            .matchedTransitionSource(id: card.id, in: cardZoom)
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
                    description: Text("옆 사람과 아이폰을 맞대보세요 — 그게 전부입니다")
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
                        .matchedTransitionSource(id: gyeop.counterpartCard.id, in: cardZoom)
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
