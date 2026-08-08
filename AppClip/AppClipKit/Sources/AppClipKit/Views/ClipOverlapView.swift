import CardKit
import Core
import DesignSystem
import SwiftUI

/// 7 `overlap` — 겹 결과. 겹치는 관심사를 먼저 보여주고 「카드 받기」로 `keep`에 넘긴다.
/// 겹침 0개 변형("겹치는 관심사는 없지만")은 navigation-map §2. 카피는 gyeop-prototype.html.
public struct ClipOverlapView: View {
    let myCard: CardSnapshot?
    let record: GyeopRecord
    let onAccept: () -> Void

    public init(myCard: CardSnapshot?, record: GyeopRecord, onAccept: @escaping () -> Void) {
        self.myCard = myCard
        self.record = record
        self.onAccept = onAccept
    }

    private var sharedInterests: [String] {
        guard let myCard else { return [] }
        return myCard.sharedInterests(with: record.counterpartCard)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                VStack(spacing: DS.Spacing.s) {
                    Text(title)
                        .font(DS.Typo.largeTitle)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("clip.overlap.title")
                    Text("여기서 대화를 시작하세요 — 앱이 아니라, 지금 눈앞의 사람과.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("겹치는 관심사")
                        .font(DS.Typo.headline)
                    interestChips
                    Text(talkLine)
                        .font(DS.Typo.caption)
                        .foregroundStyle(DS.Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.m)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(overlapAccessibilityLabel)

                CardView(card: record.counterpartCard)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onAccept()
            } label: {
                Text("카드 받기")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("clip.overlap.accept")
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
    }

    private var title: String {
        let shared = sharedInterests
        guard !shared.isEmpty else { return "겹치는 관심사는 없지만" }
        let leading = shared.prefix(2).joined(separator: "·")
        let rest = shared.count > 2 ? " 외 \(shared.count - 2)개" : ""
        return "\(leading)\(rest)가 겹쳐요"
    }

    private var talkLine: String {
        if let first = sharedInterests.first {
            return "\"\(first) 좋아하세요? 저도요\" — 첫 마디는 이미 준비됐어요."
        }
        return "성향이 닿아 있어요 — 서로 없는 걸 갖고 있다는 것도 대화가 됩니다."
    }

    /// 겹친 관심사는 강조, 상대만 가진 관심사는 흐리게 — 프로토타입 overlap-chips 구성.
    @ViewBuilder
    private var interestChips: some View {
        let shared = sharedInterests
        let counterpartOnly = record.counterpartCard.interests.filter { !shared.contains($0) }
        if shared.isEmpty, counterpartOnly.isEmpty {
            Text("이번엔 등록된 관심사가 없었어요")
                .font(DS.Typo.caption)
                .foregroundStyle(DS.Palette.secondaryText)
        } else {
            FlowChips(highlighted: shared, dimmed: counterpartOnly)
        }
    }

    private var overlapAccessibilityLabel: String {
        let counterpartOnly = record.counterpartCard.interests.filter { !sharedInterests.contains($0) }
        let sharedPart = sharedInterests.isEmpty
            ? "겹치는 관심사 없음"
            : "겹치는 관심사: \(sharedInterests.joined(separator: ", "))"
        let counterpartPart = counterpartOnly.isEmpty
            ? ""
            : ". 상대만 가진 관심사: \(counterpartOnly.joined(separator: ", "))"
        return "\(sharedPart)\(counterpartPart). \(talkLine)"
    }
}

/// 관심사 칩 나열 (겹침 강조/비겹침 흐림). 시스템 레이아웃 컴포넌트만 사용.
private struct FlowChips: View {
    let highlighted: [String]
    let dimmed: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 96), spacing: DS.Spacing.xs)],
            spacing: DS.Spacing.xs
        ) {
            ForEach(highlighted, id: \.self) { interest in
                chip(interest, emphasized: true)
            }
            ForEach(dimmed, id: \.self) { interest in
                chip(interest, emphasized: false)
            }
        }
    }

    /// 겹친 칩은 본앱과 같은 overlap 3값(bg/line/ink) — 두 레인의 겹침 색이 갈라지지 않게 한다.
    /// 비겹침은 중립 표면색 + 보조 텍스트 (프로토타입 `.oc.dim` 관습).
    @ViewBuilder
    private func chip(_ text: String, emphasized: Bool) -> some View {
        if emphasized {
            Text(text)
                .font(DS.Typo.caption)
                .foregroundStyle(DS.Palette.overlapInk)
                .padding(.horizontal, DS.Spacing.s)
                .padding(.vertical, DS.Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(DS.Palette.overlapBg, in: RoundedRectangle(cornerRadius: DS.Radius.chip))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.chip)
                        .strokeBorder(DS.Palette.overlapLine)
                )
        } else {
            Text(text)
                .font(DS.Typo.caption)
                .foregroundStyle(DS.Palette.secondaryText)
                .padding(.horizontal, DS.Spacing.s)
                .padding(.vertical, DS.Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(DS.Palette.surface, in: RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
    }
}

#Preview {
    ClipOverlapView(
        myCard: MockData.sampleCards[0],
        record: MockData.sampleGyeops[1]
    ) {}
}
