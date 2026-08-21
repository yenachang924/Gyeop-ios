import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택.
struct InterestsStepView: View {
    @Binding var selected: [String]
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 선택으로 만든 카드 색 — 배경 물듦의 원천. 선택이 없으면 배경도 중립이다.
    private var backdropColors: [Color] {
        guard !selected.isEmpty else { return [] }
        return CardPreview.visual(nickname: "", emoji: "", interests: selected).colors
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                header
                interestGrid
            }
            .padding(DS.Spacing.m)
        }
        .background {
            InterestBackdrop(colors: backdropColors)
                .animation(reduceMotion ? nil : DS.Motion.dye, value: selected)
        }
        .background(DS.Palette.background)
        .navigationTitle("1 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onNext()
            } label: {
                Text("다음")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsProminentButton()
            .padding(DS.Spacing.m)
            .disabled(selected.count != ProfileInput.interestCount)
            .accessibilityIdentifier("onboarding.interests.next")
            .frame(maxWidth: .infinity)
            .dsBottomBarFade()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("요즘 나를 보여주는 관심사")
                    .font(DS.Typo.largeTitle)
                Spacer()
                Text("\(selected.count)/\(ProfileInput.interestCount)")
                    .font(DS.Typo.section)
                    .foregroundStyle(DS.Palette.accent)
                    .monospacedDigit()
                    .accessibilityLabel("\(ProfileInput.interestCount)개 중 \(selected.count)개 선택")
            }
            Text("지금의 나와 가까운 관심사 3개를 골라주세요.")
                .font(DS.Typo.body)
                .foregroundStyle(DS.Palette.secondaryText)
        }
        .accessibilityIdentifier(
            selected.isEmpty
                ? "onboarding.interests.preview.empty"
                : "onboarding.interests.preview.filled"
        )
    }

    private var interestGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            ForEach(InterestCatalog.categories) { category in
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(category.title)
                        .font(DS.Typo.footnote)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: Layout.minimumChipWidth), spacing: DS.Spacing.s)],
                        spacing: DS.Spacing.s
                    ) {
                        ForEach(category.interests, id: \.self) { interest in
                            interestChip(interest)
                        }
                    }
                }
            }
        }
    }

    private enum Layout {
        static let minimumChipWidth: CGFloat = 120
    }

    private func interestChip(_ interest: String) -> some View {
        let isSelected = selected.contains(interest)
        let isFull = selected.count >= ProfileInput.interestCount

        return Group {
            if isSelected {
                chipButton(interest, isSelected: true)
                    .dsProminentButton()
                    .tint(DS.Palette.selection)
            } else {
                chipButton(interest, isSelected: false)
                    .dsGlassButton()
                    .tint(.secondary)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(isSelected ? DS.Palette.selection : DS.Palette.secondaryText.opacity(0.35), lineWidth: isSelected ? 2 : 1)
        }
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(reduceMotion ? nil : DS.Motion.quick, value: isSelected)
        .disabled(!isSelected && isFull)
        .accessibilityLabel("관심사 \(interest)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.interest.\(interest)")
    }

    private func chipButton(_ interest: String, isSelected: Bool) -> some View {
        Button {
            if isSelected {
                selected = selected.filter { $0 != interest }
            } else if selected.count < ProfileInput.interestCount {
                selected = selected + [interest]
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                }
                Text(interest)
                    .font(DS.Typo.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
            }
            .foregroundStyle(isSelected ? DS.Palette.onSelection : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
    }
}

/// 관심사 색으로 물드는 배경 (F36). 큰 색 덩어리를 깊게 블러해 천천히 흐르게 한다 —
/// 저채도·저불투명이라 그 위의 텍스트 대비를 해치지 않고, 다크에서는 같은 색이 어두운
/// 바탕 위에서 은은하게 빛나도록 불투명도만 올린다. Reduce Motion에서는 흐르지 않는다.
private struct InterestBackdrop: View {
    let colors: [Color]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var drifting = false

    /// 네 귀퉁이에서 출발하는 색 덩어리 — 인덱스로 방향이 갈린다.
    private static let anchors: [(x: CGFloat, y: CGFloat)] = [
        (0.15, 0.18), (0.85, 0.28), (0.25, 0.78), (0.80, 0.85),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.anchors.enumerated()), id: \.offset) { index, anchor in
                    if index < colors.count {
                        Circle()
                            .fill(colors[index])
                            .frame(width: geo.size.width * Layout.blobWidthRatio)
                            .position(
                                x: geo.size.width * anchor.x + (drifting ? Layout.drift : -Layout.drift),
                                y: geo.size.height * anchor.y + (drifting ? -Layout.drift : Layout.drift)
                            )
                    }
                }
            }
            .blur(radius: Layout.blur)
            .opacity(colorScheme == .dark ? Layout.darkOpacity : Layout.lightOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Layout.driftDuration).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
    }

    /// 배경 물듦 튜닝 — 값 조정은 여기서만 (실기기 체감 대상).
    private enum Layout {
        static let blobWidthRatio: CGFloat = 0.95
        static let blur: CGFloat = 70
        /// 텍스트 대비를 지키는 상한. 이보다 올리면 본문이 읽히기 어려워진다.
        static let lightOpacity: Double = 0.20
        static let darkOpacity: Double = 0.28
        static let drift: CGFloat = 26
        static let driftDuration: TimeInterval = 9
    }
}

#Preview {
    NavigationStack {
        InterestsStepView(
            selected: .constant(Array(InterestCatalog.categories[0].interests.prefix(ProfileInput.interestCount)))
        ) {}
    }
}
