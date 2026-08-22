import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택. 선택값은 부모의 전체 값 교체 Binding으로 전달된다.
struct InterestsStepView: View {
    enum Context: Equatable {
        case onboarding
        case profileEdit

        var navigationTitle: String { self == .onboarding ? "1 / 3" : "1 / 2" }
        var heading: String {
            // 프로토타입(docs/gyeop-prototype.html)의 제목을 그대로 쓴다.
            self == .onboarding ? "요즘 나를 이루는 것" : "관심사를\n다시 골라주세요"
        }
        /// 카드 수정에는 소제목을 두지 않는다 (소유자 지시) — 제목만으로 할 일이 분명하다.
        var supportingText: String? {
            self == .onboarding ? "지금의 나와 가까운 관심사 3개를 골라주세요." : nil
        }
        var nextIdentifier: String {
            self == .onboarding ? "onboarding.interests.next" : "profile.edit.interests.next"
        }
        var interestIdentifierPrefix: String {
            self == .onboarding ? "onboarding.interest" : "profile.edit.interest"
        }
    }

    @Binding var selected: [String]
    let context: Context
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var counterPinned = false

    init(
        selected: Binding<[String]>,
        context: Context = .onboarding,
        onNext: @escaping () -> Void
    ) {
        _selected = selected
        self.context = context
        self.onNext = onNext
    }

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
        // 헤더의 카운터가 위로 밀려나면 같은 카운터가 상단에 남는다 — 스크롤을 내리는
        // 동안에도 몇 개 골랐는지 보인다 (소유자 지시).
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            let scrolledAway = offset > Layout.counterRevealOffset
            guard scrolledAway != counterPinned else { return }
            withAnimation(reduceMotion ? nil : DS.Motion.quick) { counterPinned = scrolledAway }
        }
        .overlay(alignment: .topTrailing) { pinnedCounter }
        .background {
            InterestBackdrop(colors: backdropColors)
                .animation(reduceMotion ? nil : DS.Motion.dye, value: selected)
        }
        .background(DS.Palette.background)
        .navigationTitle(context.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onNext()
            } label: {
                Text("다음")
                    .font(DS.Typo.section)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsProminentButton()
            .padding(DS.Spacing.m)
            .disabled(selected.count != ProfileInput.interestCount)
            .accessibilityIdentifier(context.nextIdentifier)
            .frame(maxWidth: .infinity)
            .dsBottomBarFade()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(context.heading)
                    .font(DS.Typo.largeTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                counterText
                    .accessibilityLabel("\(ProfileInput.interestCount)개 중 \(selected.count)개 선택")
            }
            if let supportingText = context.supportingText {
                Text(supportingText)
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            }
        }
        .accessibilityIdentifier(
            selected.isEmpty
                ? "onboarding.interests.preview.empty"
                : "onboarding.interests.preview.filled"
        )
    }

    private var counterText: some View {
        Text("\(selected.count)/\(ProfileInput.interestCount)")
            .font(DS.Typo.section)
            .foregroundStyle(DS.Palette.accent)
            .monospacedDigit()
    }

    /// 스크롤을 따라 내려오는 카운터. 헤더가 보이는 동안에는 없는 것처럼 비켜 있다가
    /// 헤더가 밀려나면 자리를 잡는다. 알약 배경을 얹으면 화면 위에 뜬 딱지처럼 보여서,
    /// 하단 바(`dsBottomBarFade`)와 같은 문법으로 **화면 배경이 위에서 옅어지는 띠**만
    /// 깔고 그 위에 숫자를 올린다 — 글자는 읽히고 경계는 보이지 않는다.
    private var pinnedCounter: some View {
        counterText
            .padding(.trailing, DS.Spacing.m)
            .padding(.top, DS.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: DS.Palette.background, location: 0),
                        .init(color: DS.Palette.background.opacity(0.85), location: 0.45),
                        .init(color: DS.Palette.background.opacity(0), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: Layout.pinnedCounterFadeHeight)
                .allowsHitTesting(false)
            }
            .opacity(counterPinned ? 1 : 0)
            .allowsHitTesting(false)
            // 헤더의 카운터가 이미 같은 값을 읽어준다 — 보이스오버에 두 번 들리지 않게.
            .accessibilityHidden(true)
    }

    private var interestGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            ForEach(InterestCatalog.categories) { category in
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(category.title)
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(
                        columns: interestColumns,
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
        /// 헤더의 카운터가 상단 밖으로 나가는 지점 — 이때부터 고정 카운터가 자리를 잡는다.
        static let counterRevealOffset: CGFloat = 44
        /// 3개를 다 골라 더 담을 수 없는 칩의 흐림 정도.
        static let unavailableChipOpacity: CGFloat = 0.45
        /// 고정 카운터 뒤에서 배경이 옅어지며 사라지는 띠의 높이.
        static let pinnedCounterFadeHeight: CGFloat = 76
    }

    private var interestColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [GridItem(.adaptive(minimum: Layout.minimumChipWidth), spacing: DS.Spacing.s)]
    }

    private func interestChip(_ interest: String) -> some View {
        let isSelected = selected.contains(interest)
        let isFull = selected.count >= ProfileInput.interestCount

        return chipButton(interest, isSelected: isSelected)
            // MBTI 알약과 같은 표면 문법 (소유자 지시) — 선택 여부로 버튼 스타일을
            // 갈아끼우지 않고 **같은 유리에 액센트 틴트만** 더한다. 외곽선은 긋지 않는다:
            // 유리 자체가 경계를 만든다. 스타일 교체를 피하는 이유는 F68(깜빡임)과 같다.
            .modifier(InterestChipSurface(isSelected: isSelected))
            // 고를 수 없는 칩은 잠잠하게 — 이전 bordered 스타일이 주던 흐림을 유지한다.
            .opacity(!isSelected && isFull ? Layout.unavailableChipOpacity : 1)
            .scaleEffect(isSelected ? 1.04 : 1)
        .animation(reduceMotion ? nil : DS.Motion.quick, value: isSelected)
        .disabled(!isSelected && isFull)
        .accessibilityLabel("관심사 \(interest)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("\(context.interestIdentifierPrefix).\(interest)")
    }

    private func chipButton(_ interest: String, isSelected: Bool) -> some View {
        Button {
            if isSelected {
                selected = selected.filter { $0 != interest }
            } else if selected.count < ProfileInput.interestCount {
                selected = selected + [interest]
            }
        } label: {
            // 체크 표시 없이 색만으로 고른 것을 말한다 (소유자 지시) — 아이콘이 들고 나며
            // 글자가 밀리지 않아 알약 폭도 일정하게 유지된다. 선택 사실은 접근성
            // 트레이트(.isSelected)가 따로 전달한다.
            Text(interest)
                .font(DS.Typo.headline)
                // 글자가 커진 만큼 한 줄에 안 들어갈 수 있다 — 자르지 말고 흘려보낸다.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity, minHeight: DS.Layout.primaryActionHeight)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// 관심사 알약 표면 — MBTI 알약(`MBTIPillSurface`)과 같은 모양·같은 원리.
/// 선택은 액센트 틴트로만 말하고, 미선택은 맨 유리다. 하드 스트로크를 두지 않는다.
private struct InterestChipSurface: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                isSelected ? .regular.tint(DS.Palette.accent) : .regular,
                in: Capsule()
            )
        } else {
            content
                .background {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(DS.Palette.accent)
                            .opacity(isSelected ? 1 : 0)
                    }
                }
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
