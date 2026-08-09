import Core
import DesignSystem
import SwiftUI

/// 1 `clip` — 카드 수신. 발신자 표시 + 「내 카드 만들기」 + 「카드는 어떻게 만들어지나요?」 설명 시트.
///
/// 발신자의 실제 카드 비주얼은 여기서 못 그린다 — 인보케이션 URL에는 토큰(t)·닉네임(n)만 있고
/// 카드 데이터는 맞대기(교환)에서야 도착한다. 토큰→카드 조회가 생기면 CardView로 교체할 것.
public struct ClipReceptionView: View {
    let inviterNickname: String?
    let onCreateCard: () -> Void

    @State private var isShowingHowSheet = false

    public init(inviterNickname: String?, onCreateCard: @escaping () -> Void) {
        self.inviterNickname = inviterNickname
        self.onCreateCard = onCreateCard
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(headline)
                    .font(DS.Typo.largeTitle)
                Text("내 카드를 만들어 맞대면, 서로 겹치는 관심사가 그 자리에서 보여요. 15초면 됩니다.")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            }

            if let inviterNickname {
                GroupBox {
                    // Dynamic Type 극단에서 두 텍스트가 한 줄을 두고 경쟁하지 않도록,
                    // 안 맞으면 세로로 쌓는다.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DS.Spacing.s) {
                            Text(inviterNickname)
                                .font(DS.Typo.headline)
                            Spacer()
                            Text("카드는 맞댄 뒤에 열려요")
                                .font(DS.Typo.footnote)
                                .foregroundStyle(DS.Palette.secondaryText)
                        }
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(inviterNickname)
                                .font(DS.Typo.headline)
                            Text("카드는 맞댄 뒤에 열려요")
                                .font(DS.Typo.footnote)
                                .foregroundStyle(DS.Palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: DS.minTapTarget)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(inviterNickname)님의 카드. 맞댄 뒤에 열려요")
            }

            Spacer()

            VStack(spacing: DS.Spacing.s) {
                Button {
                    onCreateCard()
                } label: {
                    Text("내 카드 만들기")
                        .font(DS.Typo.headline)
                        .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                }
                .dsProminentButton()
                .accessibilityIdentifier("clip.reception.createCard")

                Button {
                    isShowingHowSheet = true
                } label: {
                    Text("카드는 어떻게 만들어지나요?")
                        .font(DS.Typo.body)
                        .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                }
                .dsGlassButton()
                .accessibilityIdentifier("clip.reception.how")
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.background)
        .sheet(isPresented: $isShowingHowSheet) {
            howSheet
        }
    }

    private var headline: String {
        if let inviterNickname {
            return "\(inviterNickname)님이\n카드를 건넸어요"
        }
        return "카드를 건네받았어요"
    }

    private var howSheet: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("카드는 어떻게 만들어지나요?")
                .font(DS.Typo.title)
            Text("관심사·성향·한 줄, 세 가지 입력이 시드가 되어 카드의 색과 결이 정해져요. 같은 입력이면 언제나 같은 카드. 사진도 계정도 필요 없어요.")
                .font(DS.Typo.body)
                .foregroundStyle(DS.Palette.secondaryText)
            Spacer()
            Button {
                isShowingHowSheet = false
            } label: {
                Text("닫기")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsGlassButton()
            .accessibilityIdentifier("clip.reception.how.close")
        }
        .padding(DS.Spacing.m)
        .presentationDetents([.medium])
    }
}

#Preview {
    ClipReceptionView(inviterNickname: "지수") {}
}
