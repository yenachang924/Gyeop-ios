import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택 (최대 5개).
///
/// F36: 카드 프리뷰를 **화면에서 뺐다**. 대신 **배경이 고른 관심사의 색으로 은은하게
/// 물들고 천천히 흐른다.** 배경은 저채도·고블러라 텍스트 가독성을 해치지 않는다.
///
/// F57 (카드 리디자인 라운드): 칩 무더기를 **카테고리 구획**으로 나눴다 — 섹션 헤더와
/// 여백만으로 구획하고 흰 컨테이너 칸은 두지 않는다 (소유자 지시). 카테고리는 이모지
/// 카탈로그의 실분류(활동·취미·음식·동물·자연 등)를 CSV 순서 그대로 쓴다.
/// 「다음」은 하단 고정 CTA — 어떤 칩보다 크다.
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
            // 카운터는 제목 줄로 올라갔다 (F61). CTA는 「다음」 하나만 말하고,
            // 화면에서 가장 도드라진다 (F62 — 카드 완성 버튼과 같은 전폭 구성).
            // F65: CTA 뒤에 블러 바 — 스크롤되는 칩이 버튼 밑을 지나가도 읽힌다 (사진 앱 문법).
            Button {
                onNext()
            } label: {
                Text("다음")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .dsProminentButton()
            .padding(DS.Spacing.m)
            .disabled(selected.isEmpty)
            .accessibilityIdentifier("onboarding.interests.next")
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("요즘 나를 이루는 것")
                    .font(DS.Typo.largeTitle)
                Spacer()
                // 진행 카운터는 제목 줄 오른쪽, 브랜드 레드 (F61 — 소유자 목업 "1/5")
                Text("\(selected.count)/\(UserProfile.maxInterests)")
                    .font(DS.Typo.section)
                    .foregroundStyle(DS.Palette.accent)
                    .monospacedDigit()
                    .accessibilityLabel("\(UserProfile.maxInterests)개 중 \(selected.count)개 선택")
            }
            Text("최대 \(UserProfile.maxInterests)개 고를 수 있어요")
                .font(DS.Typo.body)
                .foregroundStyle(DS.Palette.secondaryText)
        }
        .accessibilityIdentifier(
            selected.isEmpty
                ? "onboarding.interests.preview.empty"
                : "onboarding.interests.preview.filled"
        )
    }

    /// 카테고리 구획 (F57) — 헤더 + 여백이 구획을 만들고, 컨테이너 칸은 없다.
    /// 칩 폭(F36)은 유지 — 이름이 줄바꿈·축소되지 않게.
    private var interestGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            ForEach(EmojiCatalog.categories, id: \.self) { category in
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(category)
                        .font(DS.Typo.footnote)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(
                        // 컴팩트 칩 (F61 → F64에서 다시 -20%). 폭을 줄이는 대신
                        // 글자 축소 하한(0.75)이 이름을 지킨다.
                        columns: [GridItem(.adaptive(minimum: 76), spacing: DS.Spacing.s)],
                        spacing: DS.Spacing.s
                    ) {
                        // 이름이 긴 항목은 선택지에서 뺀다 (F65·F66) — 칩에서 …로 잘리는
                        // 문제의 근본 해결 (소유자 결정). 이모지 자체는 3/3 키보드로 여전히 열려 있다.
                        ForEach(
                            EmojiCatalog.icons(in: category)
                                .filter { $0.name.count <= Layout.maxNameLength }
                        ) { icon in
                            interestChip(icon)
                        }
                    }
                }
            }
        }
    }

    private enum Layout {
        /// 칩 라벨 높이 (F64 — 스타일 패딩 포함 최종 ≈44pt).
        static let chipLabelHeight: CGFloat = 30
        /// 선택지 이름 길이 상한 (F66) — 이모지와 함께 넣을 때 이보다 길면
        /// 컴팩트 4열 칩에서 …로 잘린다. 137개 중 17개 제외, 120개 노출.
        static let maxNameLength = 3
    }

    private func interestChip(_ icon: EmojiIcon) -> some View {
        let isSelected = selected.contains(icon.name)
        let isFull = selected.count >= UserProfile.maxInterests

        // 선택 상태는 액센트가 아니라 무채 잉크 채움 — 칩 5개 선택 시 화면이 빨강으로
        // 넘치지 않게 한다 (U1 원칙 1, 프로토타입 chip[aria-pressed] 관습).
        return Group {
            if isSelected {
                chipButton(icon, isSelected: true)
                    .dsProminentButton()
                    .tint(DS.Palette.selection)
            } else {
                chipButton(icon, isSelected: false)
                    .dsGlassButton()
                    .tint(.secondary)
            }
        }
        // 선택 스프링 스케일 — 잦은 인터랙션이라 quick (살짝만 커진다)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(reduceMotion ? nil : DS.Motion.quick, value: isSelected)
        .disabled(!isSelected && isFull)
        .accessibilityLabel("관심사 \(icon.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.interest.\(icon.name)")
    }

    /// borderedProminent가 다크에서 흰 채움(primary 반전)이 되므로 라벨은 onSelection으로 명시.
    private func chipButton(_ icon: EmojiIcon, isSelected: Bool) -> some View {
        Button {
            if isSelected {
                selected.removeAll { $0 == icon.name }
            } else if selected.count < UserProfile.maxInterests {
                selected.append(icon.name)
            }
        } label: {
            // F66: 이모지 유지 (소유자 재결정 — F65의 텍스트 전용을 되돌림).
            // 대신 이모지와 함께 넣으면 …로 넘치는 이름(4글자 이상)은 선택지에서 뺀다.
            HStack(spacing: DS.Spacing.xs) {
                Text(icon.emoji)
                Text(icon.name)
                    .font(DS.Typo.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
            }
            .foregroundStyle(isSelected ? DS.Palette.onSelection : Color.secondary)
            // 라벨 높이를 낮춰도 버튼 스타일 패딩을 더하면 최종 높이가 44pt 언저리 —
            // 시각은 -20%, 터치 타깃 규칙(HIG 44pt)은 지켜진다.
            .frame(maxWidth: .infinity, minHeight: Layout.chipLabelHeight)
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
        InterestsStepView(selected: .constant(["클라이밍"])) {}
    }
}
