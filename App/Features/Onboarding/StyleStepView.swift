import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — 여가 성향 2×2 (정적/동적 × 실내/실외). 4택1로 고르면 선택이 표시되고,
/// 「다음」으로 넘어간다 — 미선택이면 다음 비활성 (navigation-map §1-3).
struct StyleStepView: View {
    @Binding var selected: LeisureStyle?
    let onNext: () -> Void

    private static let examples: [LeisureStyle: String] = [
        LeisureStyle(energy: .calm, venue: .indoor): "보드게임 · 독서",
        LeisureStyle(energy: .calm, venue: .outdoor): "산책 · 일몰",
        LeisureStyle(energy: .active, venue: .indoor): "클라이밍 · 볼링",
        LeisureStyle(energy: .active, venue: .outdoor): "러닝 · 서핑",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("쉬는 날의 나는")
                    .font(DS.Typo.largeTitle)
                Text("하나만 — 성향의 결이 카드의 질감을 정해요")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            }

            Grid(horizontalSpacing: DS.Spacing.s, verticalSpacing: DS.Spacing.s) {
                ForEach(LeisureStyle.Energy.allCases, id: \.self) { energy in
                    GridRow {
                        ForEach(LeisureStyle.Venue.allCases, id: \.self) { venue in
                            styleCell(LeisureStyle(energy: energy, venue: venue))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(DS.Spacing.m)
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

    private func styleCell(_ style: LeisureStyle) -> some View {
        Button {
            selected = style
        } label: {
            VStack(spacing: DS.Spacing.s) {
                Text(style.label)
                    .font(DS.Typo.headline)
                Text(Self.examples[style] ?? "")
                    .font(DS.Typo.caption)
                    .foregroundStyle(DS.Palette.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget * 2)
        }
        .buttonStyle(.bordered)
        .tint(selected == style ? DS.Palette.accent : .secondary)
        .accessibilityLabel("여가 성향 \(style.label)")
        .accessibilityAddTraits(selected == style ? .isSelected : [])
        .accessibilityIdentifier("onboarding.style.\(style.energy.rawValue)-\(style.venue.rawValue)")
    }
}

#Preview {
    NavigationStack {
        StyleStepView(selected: .constant(nil)) {}
    }
}
