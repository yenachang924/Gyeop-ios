import CardKit
import Core
import DesignSystem
import SwiftUI

/// 카드 상세 — 유리 카드 플립이 주인공이다 (F54).
///
/// F31 개정: 관심사·MBTI 나열이 **카드 뒷면으로 흡수**되면서 상세의 별도 목록은
/// 걷어냈다. 카드 아래에는 상대 카드면 겹치는 관심사, 내 카드면 공유 경로만 남는다.
/// 시트 배경은 블러 유리 (F59) — 뒤의 컬렉션 색이 은은하게 비친다.
struct CardDetailView: View {
    let card: CardSnapshot
    let myCard: CardSnapshot?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// 공유용 카드 이미지 — ImageRenderer 비용이 있어 화면 진입 후 한 번만 만든다.
    @State private var exportedCard: Image?
    @State private var showingReport = false
    @State private var confirmingBlock = false
    @State private var blockFailed = false

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
                VStack(spacing: DS.Spacing.m) {
                    CardFlipView(card: card)
                        .frame(maxWidth: DS.Layout.cardDetailMaxWidth)

                    Text("카드를 탭하면 뒤집혀요")
                        .font(DS.Typo.footnote)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityHidden(true) // CardFlipView가 힌트를 전달한다

                    if !sharedInterests.isEmpty {
                        sharedSection
                            .padding(.top, DS.Spacing.s)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
            }
            .defaultScrollAnchor(.center)
            .navigationTitle(card.nickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isMyCard {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("카드 신고", systemImage: "flag") { showingReport = true }
                            Button("사용자 차단", systemImage: "person.crop.circle.badge.xmark", role: .destructive) {
                                confirmingBlock = true
                            }
                        } label: {
                            Label("카드 관리", systemImage: "ellipsis.circle")
                        }
                        .accessibilityIdentifier("cardDetail.safety")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // 무채 크롬 — 이 화면의 주인공은 카드다 (U1 원칙 3)
                    Button { dismiss() } label: {
                        Label("닫기", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                        .tint(.primary)
                        .accessibilityLabel("닫기")
                }
                if isMyCard, let exportedCard {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: exportedCard,
                            preview: SharePreview("\(card.nickname)의 카드", image: exportedCard)
                        ) {
                            Label("이미지로 공유", systemImage: "square.and.arrow.up")
                        }
                        .tint(.primary)
                        .accessibilityIdentifier("cardDetail.share")
                    }
                }
            }
            .task { prepareShareImage() }
        }
        .sheet(isPresented: $showingReport) { CardReportView(card: card) }
        .alert("이 사용자를 차단할까요?", isPresented: $confirmingBlock) {
            Button("차단", role: .destructive) {
                Task {
                    if await model.blockUser(card) { dismiss() } else { blockFailed = true }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 기기에서 이 사용자의 카드와 만남 기록을 지우고 이후 카드 교환을 차단합니다. 상대가 이미 받은 내 카드는 지우지 못해요.")
        }
        .alert("차단 처리를 확인해주세요", isPresented: $blockFailed) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("일부 처리를 완료하지 못했어요. 설정의 차단 목록을 확인하고 다시 시도해주세요.")
        }
    }

    private func prepareShareImage() {
        guard isMyCard, exportedCard == nil else { return }
        #if canImport(UIKit)
        if let data = CardImageExporter.renderPNGData(for: card),
           let image = UIImage(data: data) {
            exportedCard = Image(uiImage: image)
        }
        #endif
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("겹치는 관심사 \(sharedInterests.joined(separator: ", ")). 다음에 만나면 여기서 시작하세요")
    }
}

#Preview("상대 카드") {
    CardDetailView(card: MockData.sampleCards[0], myCard: MockData.sampleCards[2])
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}

#Preview("내 카드") {
    CardDetailView(card: MockData.sampleCards[0], myCard: MockData.sampleCards[0])
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
