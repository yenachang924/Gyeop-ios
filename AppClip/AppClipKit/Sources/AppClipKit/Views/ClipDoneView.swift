import CardKit
import Core
import DesignSystem
import SwiftUI

/// 9 `done` — 나의 겹 (클립 컬렉션). 내 카드와 받은 카드가 남는다.
/// 클립의 종착점 — 설치 없이도 여기까지의 가치는 온전히 성립한다.
public struct ClipDoneView: View {
    let myCard: CardSnapshot?
    let record: GyeopRecord

    public init(myCard: CardSnapshot?, record: GyeopRecord) {
        self.myCard = myCard
        self.record = record
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("나의 겹")
                        .font(DS.Typo.largeTitle)
                        .accessibilityIdentifier("clip.done.title")
                    Text("스쳐 지나갈 뻔한 만남이, 여기 남아요.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                if let myCard {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("나")
                            .font(DS.Typo.headline)
                        CardView(card: myCard)
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("겹 1 · 오늘")
                        .font(DS.Typo.headline)
                    CardView(card: record.counterpartCard)
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Palette.background)
    }
}

#Preview {
    ClipDoneView(myCard: MockData.sampleCards[0], record: MockData.sampleGyeops[1])
}
