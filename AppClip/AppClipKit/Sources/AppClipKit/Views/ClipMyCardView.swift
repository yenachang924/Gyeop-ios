import CardKit
import Core
import DesignSystem
import SwiftUI

/// 5 `card` — 내 카드 완성. 「맞대기」로 `bump` 진입 (navigation-map §1-5).
public struct ClipMyCardView: View {
    let card: CardSnapshot
    let inviterNickname: String?
    let onBump: () -> Void

    public init(card: CardSnapshot, inviterNickname: String?, onBump: @escaping () -> Void) {
        self.card = card
        self.inviterNickname = inviterNickname
        self.onBump = onBump
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("이게 나예요")
                        .font(DS.Typo.largeTitle)
                        .multilineTextAlignment(.center)
                    Text("같은 입력이면, 언제나 같은 카드. 카드가 곧 나입니다.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                CardView(card: card)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .padding(DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onBump()
            } label: {
                Text(bumpLabel)
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsProminentButton()
            .accessibilityIdentifier("clip.card.bump")
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
    }

    private var bumpLabel: String {
        if let inviterNickname {
            return "\(inviterNickname)님과 맞대기"
        }
        return "맞대기"
    }
}

#Preview {
    ClipMyCardView(card: MockData.sampleCards[0], inviterNickname: "지수") {}
}
