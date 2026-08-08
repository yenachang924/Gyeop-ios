import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — 여가 성향을 2축 슬라이더로 잡는다 (F17, 레퍼런스: 건강 앱 마음챙김
/// "심리 상태"). 잔잔↔활발 · 실내↔실외 두 축이 카드 프리뷰 색에 연속적으로 기여하고
/// (`CardPreview.blendedColors` 이중선형 보간), 저장값은 4분면으로 양자화된
/// `LeisureStyle`이다 — 미양자화 상태(슬라이더 미조작)면 다음 비활성 (navigation-map §1-3).
struct StyleStepView: View {
    @Binding var selected: LeisureStyle?
    /// 1/3에서 고른 관심사 — 유동 프리뷰의 색 계산에 들어간다 (F17)
    var interests: [String] = []
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 진입 시 요소가 하나씩 내려앉는 등장 (F12) — Reduce Motion은 즉시 표시.
    @State private var appeared = false
    /// 축 값 (0~1). 중앙에서 시작하고, 조작해야 selected가 잡힌다.
    @State private var energy: Double = 0.5
    @State private var venue: Double = 0.5

    private static let examples: [LeisureStyle: String] = [
        LeisureStyle(energy: .calm, venue: .indoor): "보드게임 · 독서",
        LeisureStyle(energy: .calm, venue: .outdoor): "산책 · 일몰",
        LeisureStyle(energy: .active, venue: .indoor): "클라이밍 · 볼링",
        LeisureStyle(energy: .active, venue: .outdoor): "러닝 · 서핑",
    ]

    private var quantized: LeisureStyle {
        LeisureStyle(
            energy: energy < 0.5 ? .calm : .active,
            venue: venue < 0.5 ? .indoor : .outdoor
        )
    }

    /// 유동 프리뷰용 카드 껍데기 — 색은 colorsOverride가 전담하므로 시드는 형식값이다.
    private var previewCard: CardSnapshot {
        CardSnapshot(
            ownerID: "preview",
            seed: CardSeed.hash(
                nickname: "", emoji: "", interests: interests, leisureStyle: quantized
            ),
            nickname: "",
            tagline: "",
            emoji: "",
            interests: interests,
            leisureStyle: quantized,
            version: 1,
            createdAt: .now
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("쉬는 날의 나는")
                        .font(DS.Typo.largeTitle)
                    Text("결을 따라 움직여 보세요. 카드가 함께 물들어요.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                }
                .entrance(appeared, index: 0, reduceMotion: reduceMotion)

                CardView(
                    card: previewCard,
                    colorsOverride: CardPreview.blendedColors(
                        nickname: "", emoji: "", interests: interests,
                        energy: energy, venue: venue
                    )
                )
                .padding(.horizontal, DS.Spacing.xl)
                .entrance(appeared, index: 1, reduceMotion: reduceMotion)
                .accessibilityLabel("카드 미리보기, 성향을 움직이면 색이 흐르며 바뀌어요")

                VStack(spacing: DS.Spacing.m) {
                    axisSlider(
                        value: $energy,
                        leading: "잔잔", trailing: "활발",
                        label: "여가 에너지",
                        identifier: "onboarding.style.energy"
                    )
                    axisSlider(
                        value: $venue,
                        leading: "실내", trailing: "실외",
                        label: "여가 장소",
                        identifier: "onboarding.style.venue"
                    )
                }
                .entrance(appeared, index: 2, reduceMotion: reduceMotion)

                // 양자화 결과 — 조작 전에는 안내만 (다음도 그때까지 비활성)
                Group {
                    if selected != nil {
                        Text("\(quantized.label) · \(Self.examples[quantized] ?? "")")
                            .font(DS.Typo.headline)
                    } else {
                        Text("두 축을 움직이면 성향이 잡혀요")
                            .font(DS.Typo.subheadline)
                            .foregroundStyle(DS.Palette.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .animation(reduceMotion ? nil : DS.Motion.quick, value: quantized)
                .entrance(appeared, index: 3, reduceMotion: reduceMotion)
                .accessibilityIdentifier("onboarding.style.result")
            }
            .padding(DS.Spacing.m)
        }
        // 내용이 화면보다 작으면 세로 중앙에 앉는다 (F13 — 상단 고정 폐기)
        .defaultScrollAnchor(.center)
        .onAppear {
            appeared = true
            // 뒤로 돌아온 경우 이전 선택을 축 위치로 복원
            if let selected {
                energy = selected.energy == .calm ? 0.25 : 0.75
                venue = selected.venue == .indoor ? 0.25 : 0.75
            }
        }
        .onChange(of: energy) { selected = quantized }
        .onChange(of: venue) { selected = quantized }
        .background(DS.Palette.background)
        .navigationTitle("2 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("다음") { onNext() }
                .dsProminentButton()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .disabled(selected == nil)
                .accessibilityIdentifier("onboarding.style.next")
        }
    }

    private func axisSlider(
        value: Binding<Double>,
        leading: String, trailing: String,
        label: String,
        identifier: String
    ) -> some View {
        HStack(spacing: DS.Spacing.s) {
            Text(leading)
                .font(DS.Typo.subheadline)
                .foregroundStyle(DS.Palette.secondaryText)
            Slider(value: value)
                .accessibilityLabel(label)
                .accessibilityIdentifier(identifier)
            Text(trailing)
                .font(DS.Typo.subheadline)
                .foregroundStyle(DS.Palette.secondaryText)
        }
    }
}

/// F12 진입 등장 — 요소가 순서대로 내려앉는다. StyleStepView 전용 헬퍼.
private extension View {
    func entrance(_ appeared: Bool, index: Int, reduceMotion: Bool) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(
                reduceMotion ? nil : DS.Motion.settle.delay(Double(index) * 0.06),
                value: appeared
            )
    }
}

#Preview {
    NavigationStack {
        StyleStepView(selected: .constant(nil), interests: ["클라이밍", "커피"]) {}
    }
}
