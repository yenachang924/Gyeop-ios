import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — MBTI 선택 (F55, "쉬는 날의 나" 성향 슬라이더(F17·F48·F52) 대체).
///
/// 담백한 구성 (소유자 지시): 왼쪽 정렬 제목, 축 이름도 설명도 없이 **알약 4쌍과
/// 결과 타일 4개뿐.** 모든 컴포넌트는 리퀴드 글라스, 텍스트는 무채(라이트 검정 /
/// 다크 흰색), 선택은 색이 아니라 **유리 두께**로 구분한다 — 고른 쪽 유리가
/// 불투명해지고 살짝 떠오른다. 액센트는 「다음」 버튼 한 곳뿐이다.
///
/// 평소 배경은 비어 있고, **알약을 누르는 순간에만** 1/3에서 고른 내 색이 배경에
/// 한 번 피었다 진다 (stir(F11)의 언어를 배경으로 옮긴 것). Reduce Motion이면 생략.
///
/// MBTI는 강제하지 않는다 — 「건너뛰기」가 항상 열려 있고, 건너뛰면 카드 뒷면에
/// 표기가 없을 뿐이다.
struct MBTIStepView: View {
    @Binding var selected: MBTI?
    /// 1/3에서 고른 관심사 — 누를 때 배경에 피는 색의 원천.
    var interests: [String] = []
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var energy: MBTI.Energy?
    @State private var perception: MBTI.Perception?
    @State private var judgment: MBTI.Judgment?
    @State private var lifestyle: MBTI.Lifestyle?
    /// 탭마다 하나씩 태어나는 배경 색 흐름 — 애니메이션이 끝나면 스스로 걷힌다.
    @State private var blooms: [Bloom] = []

    private var composed: MBTI? {
        guard let energy, let perception, let judgment, let lifestyle else { return nil }
        return MBTI(energy: energy, perception: perception, judgment: judgment, lifestyle: lifestyle)
    }

    /// 배경에 피는 색 — 내 관심사로 만든 카드 색이다 (1/3 배경 물듦과 같은 원천).
    private var bloomColors: [Color] {
        CardPreview.visual(nickname: "", emoji: "", interests: interests).colors
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                Text("MBTI가\n무엇인가요?")
                    .font(DS.Typo.largeTitle)

                tiles

                VStack(spacing: DS.Spacing.s) {
                    pairRow(axis: 0, options: MBTI.Energy.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: energy?.rawValue) { energy = MBTI.Energy(rawValue: $0) }
                    pairRow(axis: 1, options: MBTI.Perception.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: perception?.rawValue) { perception = MBTI.Perception(rawValue: $0) }
                    pairRow(axis: 2, options: MBTI.Judgment.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: judgment?.rawValue) { judgment = MBTI.Judgment(rawValue: $0) }
                    pairRow(axis: 3, options: MBTI.Lifestyle.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: lifestyle?.rawValue) { lifestyle = MBTI.Lifestyle(rawValue: $0) }
                }
            }
            .padding(DS.Spacing.m)
        }
        .background { bloomLayer }
        .background(DS.Palette.background)
        .navigationTitle("2 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: restore)
        .onChange(of: composed) { selected = composed }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: DS.Spacing.xs) {
                Button("다음") { onNext() }
                    .dsProminentButton()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(composed == nil)
                    .accessibilityIdentifier("onboarding.mbti.next")
                Button("건너뛰기") {
                    selected = nil
                    onNext()
                }
                .font(DS.Typo.footnote)
                .tint(DS.Palette.secondaryText)
                .frame(minHeight: DS.minTapTarget)
                .accessibilityIdentifier("onboarding.mbti.skip")
            }
            .padding(.horizontal, DS.Spacing.m)
            .padding(.bottom, DS.Spacing.s)
        }
    }

    /// 뒤로 돌아온 경우 이전 선택을 네 축에 복원.
    private func restore() {
        guard let selected else { return }
        energy = selected.energy
        perception = selected.perception
        judgment = selected.judgment
        lifestyle = selected.lifestyle
    }

    // MARK: - 결과 타일

    /// 완성되어 가는 4글자 — 안 고른 축은 점으로 자리만 지킨다.
    private var tiles: some View {
        HStack(spacing: DS.Spacing.s) {
            tile(letter: energy?.rawValue)
            tile(letter: perception?.rawValue)
            tile(letter: judgment?.rawValue)
            tile(letter: lifestyle?.rawValue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(composed.map { "선택한 MBTI \($0.code)" } ?? "MBTI 미완성")
        .accessibilityIdentifier("onboarding.mbti.tiles")
    }

    private func tile(letter: String?) -> some View {
        Text(letter ?? "·")
            .font(DS.Typo.title)
            .foregroundStyle(letter == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
            .frame(width: DS.minTapTarget, height: DS.minTapTarget)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip).strokeBorder(.quaternary))
            .animation(reduceMotion ? nil : DS.Motion.quick, value: letter)
    }

    // MARK: - 알약 쌍

    private func pairRow(
        axis: Int,
        options: [(letter: String, word: String)],
        selectedLetter: String?,
        choose: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(options, id: \.letter) { option in
                pill(
                    letter: option.letter,
                    word: option.word,
                    isSelected: selectedLetter == option.letter
                ) {
                    choose(option.letter)
                    bloom(axis: axis)
                }
            }
        }
    }

    /// 선택 = 유리 두께: 미선택은 옅은 유리 + 회색 글자, 선택은 불투명 유리 + 진한 글자.
    /// 어느 쪽도 44pt(다음 버튼 선)를 넘지 않는다.
    private func pill(
        letter: String, word: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Group {
            if isSelected {
                pillButton(letter: letter, word: word, isSelected: true, action: action)
                    .dsProminentButton()
                    .tint(DS.Palette.surface)
                    .shadow(
                        color: .black.opacity(Layout.selectedShadowOpacity),
                        radius: Layout.selectedShadowRadius, y: 2
                    )
            } else {
                pillButton(letter: letter, word: word, isSelected: false, action: action)
                    .dsGlassButton()
                    .tint(.secondary)
            }
        }
        .animation(reduceMotion ? nil : DS.Motion.quick, value: isSelected)
        .accessibilityLabel("\(word) \(letter)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.mbti.\(letter)")
    }

    private func pillButton(
        letter: String, word: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xs) {
                Text(letter)
                    .font(DS.Typo.headline)
                Text(word)
                    .font(DS.Typo.footnote)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
    }

    // MARK: - 누를 때만 피는 배경 색 흐름

    private struct Bloom: Identifiable, Equatable {
        let id: UUID
        let color: Color
        let anchor: UnitPoint
    }

    /// 축마다 다른 자리에서 피어난다 — 좌우를 오가며 화면이 한쪽으로 쏠리지 않게.
    private static let bloomAnchors: [UnitPoint] = [
        UnitPoint(x: 0.82, y: 0.22),
        UnitPoint(x: 0.16, y: 0.42),
        UnitPoint(x: 0.84, y: 0.62),
        UnitPoint(x: 0.18, y: 0.82),
    ]

    private func bloom(axis: Int) {
        guard !reduceMotion else { return }
        let colors = bloomColors
        let color = colors[(axis * 6) % colors.count]
        blooms.append(Bloom(id: UUID(), color: color, anchor: Self.bloomAnchors[axis % 4]))
    }

    private var bloomLayer: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(blooms) { bloom in
                    BloomCircle(color: bloom.color, anchor: bloom.anchor, size: geo.size) {
                        blooms.removeAll { $0.id == bloom.id }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 배경 튜닝 상수 — 값 조정은 여기서만 (실기기 체감 대상).
    fileprivate enum Layout {
        static let bloomWidthRatio: CGFloat = 0.85
        static let bloomBlur: CGFloat = 60
        /// 피크 불투명도 — 1/3 배경 물듦(F36)과 같은 급의 상한.
        static let bloomPeakOpacity: Double = 0.4
        static let selectedShadowOpacity: Double = 0.1
        static let selectedShadowRadius: CGFloat = 6
    }
}

/// 한 번 피었다 지는 색 원 — 등장(짧게) 후 스스로 사라지고 부모에게 제거를 알린다.
private struct BloomCircle: View {
    let color: Color
    let anchor: UnitPoint
    let size: CGSize
    let onFinished: () -> Void

    @State private var risen = false
    @State private var faded = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size.width * MBTIStepView.Layout.bloomWidthRatio)
            .position(x: size.width * anchor.x, y: size.height * anchor.y)
            .blur(radius: MBTIStepView.Layout.bloomBlur)
            .scaleEffect(faded ? 1.25 : (risen ? 1 : 0.7))
            .opacity(faded ? 0 : (risen ? MBTIStepView.Layout.bloomPeakOpacity : 0))
            .onAppear {
                // 피고(짧게) → 진다(길게). 유동 무드 — 전부 무바운스.
                withAnimation(DS.Motion.settle) { risen = true }
                withAnimation(DS.Motion.bloom.delay(0.35)) { faded = true }
            }
            .task {
                try? await Task.sleep(for: .seconds(2))
                onFinished()
            }
    }
}

#Preview {
    NavigationStack {
        MBTIStepView(selected: .constant(nil), interests: ["클라이밍", "커피"]) {}
    }
}
