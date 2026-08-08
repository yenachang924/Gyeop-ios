import CardKit
import Core
import DesignSystem
import SwiftUI

/// 8 `keep` — 보관·전환 제안. **클립 레인에서 유일하게 설치를 언급하는 화면.**
/// 「전체 앱 받기」 탭에서만 SKOverlay가 뜨고, 오버레이가 닫히면(App Store 상호작용
/// 완료) `done`으로 간다. 「나중에 할게요」는 거절 비용 0으로 곧장 `done`(나의 겹)
/// (navigation-map §1-8).
public struct ClipKeepView: View {
    let myCard: CardSnapshot?
    let record: GyeopRecord
    let onLater: () -> Void
    let onInstallDismissed: () -> Void

    @State private var isPresentingOverlay = false

    public init(
        myCard: CardSnapshot?,
        record: GyeopRecord,
        onLater: @escaping () -> Void,
        onInstallDismissed: @escaping () -> Void = {}
    ) {
        self.myCard = myCard
        self.record = record
        self.onLater = onLater
        self.onInstallDismissed = onInstallDismissed
    }

    private var sharedCount: Int {
        guard let myCard else { return 0 }
        return myCard.sharedInterests(with: record.counterpartCard).count
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text("겹 1 · 첫 기록")
                        .font(DS.Typo.largeTitle)
                    Text("\(record.counterpartCard.nickname)님과의 만남이 기록됐어요.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                GroupBox {
                    // Dynamic Type 극단에서 두 텍스트가 한 줄을 두고 경쟁하지 않도록,
                    // 안 맞으면 세로로 쌓는다.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DS.Spacing.s) {
                            Text(record.counterpartCard.nickname)
                                .font(DS.Typo.headline)
                            Spacer()
                            Text("오늘 · 겹친 관심사 \(sharedCount)개")
                                .font(DS.Typo.caption)
                                .foregroundStyle(DS.Palette.secondaryText)
                        }
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(record.counterpartCard.nickname)
                                .font(DS.Typo.headline)
                            Text("오늘 · 겹친 관심사 \(sharedCount)개")
                                .font(DS.Typo.caption)
                                .foregroundStyle(DS.Palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: DS.minTapTarget)
                }
                .padding(.horizontal, DS.Spacing.m)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(record.counterpartCard.nickname)님 카드 — 오늘, 겹친 관심사 \(sharedCount)개")

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("이 카드, 계속 간직할까요?")
                        .font(DS.Typo.headline)
                    Text(ClipRetentionPolicy.noticeText())
                        .font(DS.Typo.caption)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityIdentifier("clip.keep.retentionNotice")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.m)
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: DS.Spacing.s) {
                Button {
                    // 교환 완료(keep 도달) 후에만 존재하는 버튼 — SKOverlay는 이 탭에서만 뜬다.
                    isPresentingOverlay = true
                } label: {
                    Text("전체 앱 받기")
                        .font(DS.Typo.headline)
                        .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                }
                .dsProminentButton()
                .accessibilityIdentifier("clip.keep.install")

                Button {
                    onLater()
                } label: {
                    Text("나중에 할게요")
                        .font(DS.Typo.body)
                        .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                }
                .dsGlassButton()
                .accessibilityIdentifier("clip.keep.later")
            }
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
        .appClipInstallSuggestion(isPresented: isPresentingOverlay) {
            isPresentingOverlay = false
            onInstallDismissed()
        }
    }
}

#Preview {
    ClipKeepView(
        myCard: MockData.sampleCards[0],
        record: MockData.sampleGyeops[1],
        onLater: {}
    )
}
