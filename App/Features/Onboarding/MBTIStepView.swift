import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — MBTI 선택 (F55, "쉬는 날의 나" 성향 슬라이더(F17·F48·F52) 대체).
///
/// F61 (소유자 목업 그대로): 왼쪽 정렬 제목 아래 **알약 4쌍이 세 컬럼**으로 선다 —
/// 왼쪽 선택지 · 가운데에 고른 글자가 크게(브랜드 레드) · 오른쪽 선택지.
/// 축 이름도 낱말도 결과 타일도 없다. **선택된 알약은 브랜드 레드 채움**
/// (소유자 재결정 — U1의 무채 선택 규칙에 대한 명시적 예외), 미선택은 글라스.
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
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                Text("MBTI가\n무엇인가요?")
                    .font(DS.Typo.largeTitle)

                VStack(spacing: DS.Spacing.m) {
                    pairRow(axis: 0, options: MBTI.Energy.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: energy?.rawValue) { energy = MBTI.Energy(rawValue: $0) }
                    pairRow(axis: 1, options: MBTI.Perception.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: perception?.rawValue) { perception = MBTI.Perception(rawValue: $0) }
                    pairRow(axis: 2, options: MBTI.Judgment.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: judgment?.rawValue) { judgment = MBTI.Judgment(rawValue: $0) }
                    pairRow(axis: 3, options: MBTI.Lifestyle.allCases.map { ($0.rawValue, $0.word) },
                            selectedLetter: lifestyle?.rawValue) { lifestyle = MBTI.Lifestyle(rawValue: $0) }
                }
                .padding(.top, DS.Spacing.l)
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

    // MARK: - 알약 쌍 (세 컬럼: 왼쪽 선택지 · 고른 글자 · 오른쪽 선택지)

    private func pairRow(
        axis: Int,
        options: [(letter: String, word: String)],
        selectedLetter: String?,
        choose: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: DS.Spacing.m) {
            pill(
                letter: options[0].letter,
                word: options[0].word,
                isSelected: selectedLetter == options[0].letter
            ) {
                choose(options[0].letter)
                bloom(axis: axis)
            }

            // 가운데: 이 축에서 고른 글자가 크게 선다 — 네 줄이 모여 세로로 MBTI가 완성된다.
            Text(selectedLetter ?? "·")
                .font(DS.Typo.mbtiHero)
                .foregroundStyle(
                    selectedLetter == nil ? AnyShapeStyle(.quaternary) : AnyShapeStyle(DS.Palette.accent)
                )
                .frame(width: Layout.centerLetterWidth)
                .animation(reduceMotion ? nil : DS.Motion.quick, value: selectedLetter)
                .accessibilityHidden(true) // 선택 상태는 알약이 전달한다

            pill(
                letter: options[1].letter,
                word: options[1].word,
                isSelected: selectedLetter == options[1].letter
            ) {
                choose(options[1].letter)
                bloom(axis: axis)
            }
        }
    }

    /// 선택 = 브랜드 레드 채움 (F61, 소유자 목업), 미선택 = 글라스 + 무채 글자.
    private func pill(
        letter: String, word: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Group {
            if isSelected {
                pillButton(letter: letter, isSelected: true, action: action)
            } else {
                pillButton(letter: letter, isSelected: false, action: action)
                    .tint(.secondary)
            }
        }
        .animation(reduceMotion ? nil : DS.Motion.quick, value: isSelected)
        .accessibilityLabel("\(word) \(letter)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.mbti.\(letter)")
    }

    @ViewBuilder
    private func pillButton(
        letter: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        let label = Button(action: action) {
            Text(letter)
                .font(DS.Typo.title)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity, minHeight: DS.Layout.primaryActionHeight)
        }
        // 전역 tint가 액센트라 prominent가 곧 브랜드 레드 채움이 된다 (CTA와 같은 결).
        if isSelected {
            label.dsProminentButton()
        } else {
            label.dsGlassButton()
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
        /// 가운데 큰 글자 컬럼 폭 — 네 줄의 글자가 세로로 정렬되게 고정한다.
        static let centerLetterWidth: CGFloat = 64
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
