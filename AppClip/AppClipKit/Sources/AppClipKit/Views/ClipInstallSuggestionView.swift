import CardKit
import Core
import DesignSystem
import SwiftUI

/// 겹 성립 직후 화면. 받은 카드·겹치는 관심사를 먼저 보여주고, 그 아래에서만
/// SKOverlay 설치 제안을 띄운다 — 값을 체감한 다음에 설치를 묻는 순서가 이 제품의 핵심 주장.
public struct ClipInstallSuggestionView: View {
    let myCard: CardSnapshot?
    let record: GyeopRecord

    public init(myCard: CardSnapshot?, record: GyeopRecord) {
        self.myCard = myCard
        self.record = record
    }

    private var sharedInterests: [String] {
        guard let myCard else { return [] }
        return myCard.sharedInterests(with: record.counterpartCard)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("겹 1회 완성")
                        .font(DS.Typo.largeTitle)
                    Text("\(record.counterpartCard.nickname)님과 겹쳤어요")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                CardView(card: record.counterpartCard)
                    .padding(.horizontal, DS.Spacing.xl)

                if !sharedInterests.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("겹치는 관심사")
                            .font(DS.Typo.headline)
                        HStack(spacing: DS.Spacing.xs) {
                            ForEach(sharedInterests, id: \.self) { interest in
                                Text(interest)
                                    .font(DS.Typo.caption)
                                    .padding(.horizontal, DS.Spacing.s)
                                    .padding(.vertical, DS.Spacing.xs)
                                    .background(DS.Palette.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: DS.Radius.chip))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.m)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("겹치는 관심사: \(sharedInterests.joined(separator: ", "))")
                }

                Text(ClipRetentionPolicy.noticeText())
                    .font(DS.Typo.caption)
                    .foregroundStyle(DS.Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.m)
                    .accessibilityIdentifier("clip.suggestion.retentionNotice")
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .background(DS.Palette.background)
        // 이 화면에 도달했다는 것 자체가 "교환 완료 후"라는 전제를 만족한다.
        .appClipInstallSuggestion(isPresented: true)
    }
}

#Preview {
    ClipInstallSuggestionView(
        myCard: MockData.sampleCards[0],
        record: MockData.sampleGyeops[1]
    )
}
