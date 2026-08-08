import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — 여가 성향 2×2 (정적/동적 × 실내/실외). 4택1로 고르면 선택이 표시되고,
/// 「다음」으로 넘어간다 — 미선택이면 다음 비활성 (navigation-map §1-3).
struct StyleStepView: View {
    @Binding var selected: LeisureStyle?
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 진입 시 셀이 하나씩 내려앉는 등장 (F12) — Reduce Motion은 즉시 표시.
    @State private var appeared = false

    private static let examples: [LeisureStyle: String] = [
        LeisureStyle(energy: .calm, venue: .indoor): "보드게임 · 독서",
        LeisureStyle(energy: .calm, venue: .outdoor): "산책 · 일몰",
        LeisureStyle(energy: .active, venue: .indoor): "클라이밍 · 볼링",
        LeisureStyle(energy: .active, venue: .outdoor): "러닝 · 서핑",
    ]

    var body: some View {
        // Dynamic Type 극단에서 셀 4개(각 minHeight 88pt 이상)가 화면을 넘칠 수 있어
        // InterestsStepView와 같은 패턴으로 스크롤 가능하게 한다.
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("쉬는 날의 나는")
                        .font(DS.Typo.largeTitle)
                    Text("하나만, 성향의 결이 카드의 질감을 정해요")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                Grid(horizontalSpacing: DS.Spacing.s, verticalSpacing: DS.Spacing.s) {
                    ForEach(Array(LeisureStyle.Energy.allCases.enumerated()), id: \.element) { row, energy in
                        GridRow {
                            ForEach(Array(LeisureStyle.Venue.allCases.enumerated()), id: \.element) { column, venue in
                                styleCell(
                                    LeisureStyle(energy: energy, venue: venue),
                                    entranceIndex: row * LeisureStyle.Venue.allCases.count + column
                                )
                            }
                        }
                    }
                }
            }
            .padding(DS.Spacing.m)
        }
        .onAppear { appeared = true }
        .background(DS.Palette.background)
        .navigationTitle("2 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("다음") { onNext() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .disabled(selected == nil)
                .accessibilityIdentifier("onboarding.style.next")
        }
    }

    private func styleCell(_ style: LeisureStyle, entranceIndex: Int) -> some View {
        let isSelected = selected == style

        // 선택 상태는 무채 잉크 채움 — 관심사 칩과 같은 관습 (U1 원칙 1).
        return Group {
            if isSelected {
                cellButton(style, isSelected: true)
                    .buttonStyle(.borderedProminent)
                    .tint(DS.Palette.selection)
            } else {
                cellButton(style, isSelected: false)
                    .buttonStyle(.bordered)
                    .tint(.secondary)
            }
        }
        // 4택1 선택 스프링 — 관심사 칩과 같은 결 (quick)
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(reduceMotion ? nil : DS.Motion.quick, value: selected)
        // 진입 등장 — 셀이 순서대로 내려앉는다 (F12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(
            reduceMotion ? nil : DS.Motion.settle.delay(Double(entranceIndex) * 0.06),
            value: appeared
        )
        .accessibilityLabel("여가 성향 \(style.label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.style.\(style.energy.rawValue)-\(style.venue.rawValue)")
    }

    private func cellButton(_ style: LeisureStyle, isSelected: Bool) -> some View {
        Button {
            selected = style
        } label: {
            VStack(spacing: DS.Spacing.s) {
                Text(style.label)
                    .font(DS.Typo.headline)
                    .foregroundStyle(isSelected ? DS.Palette.onSelection : Color.secondary)
                Text(Self.examples[style] ?? "")
                    .font(DS.Typo.caption)
                    .foregroundStyle(isSelected ? DS.Palette.onSelection.opacity(0.8) : DS.Palette.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget * 2)
        }
    }
}

#Preview {
    NavigationStack {
        StyleStepView(selected: .constant(nil)) {}
    }
}
