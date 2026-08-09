import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 2/3 — 여가 성향을 2축 슬라이더로 잡는다 (F17, 레퍼런스: 건강 앱 마음챙김
/// "심리 상태"). 잔잔↔활발 · 실내↔실외 두 축이 카드 프리뷰 색에 연속적으로 기여하고
/// (`CardPreview.blendedColors` 이중선형 보간), 저장값은 4분면으로 양자화된 `LeisureStyle`이다.
/// 미양자화 상태(슬라이더 미조작)면 다음 비활성 (navigation-map §1-3).
///
/// F35: 결과 라벨을 **제목 아래로 올렸다** — 하단에 두니 「다음」 버튼과 겹쳤다.
/// 슬라이더도 폭을 묶고, 카드 프리뷰는 화면을 덜 잡아먹게 줄였다.
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
            VStack(spacing: DS.Spacing.l) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("쉬는 날의 나는")
                        .font(DS.Typo.largeTitle)
                    // 결과 라벨을 제목 바로 아래로 (F35) — 하단은 「다음」 버튼 자리다
                    result
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .entrance(appeared, index: 0, reduceMotion: reduceMotion)

                CardView(
                    card: previewCard,
                    colorsOverride: CardPreview.blendedColors(
                        nickname: "", emoji: "", interests: interests,
                        energy: energy, venue: venue
                    )
                )
                // 카드를 줄여 슬라이더·버튼이 한 화면에 편히 들어오게 (F35)
                .frame(maxWidth: Layout.previewMaxWidth)
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

    /// 조작 전에는 안내, 조작 후에는 잡힌 성향 — 자리를 옮겨도 역할은 같다.
    @ViewBuilder
    private var result: some View {
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
        .animation(reduceMotion ? nil : DS.Motion.quick, value: quantized)
        .accessibilityIdentifier("onboarding.style.result")
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
            AxisSlider(value: value, label: label)
                .accessibilityIdentifier(identifier)
            Text(trailing)
                .font(DS.Typo.subheadline)
                .foregroundStyle(DS.Palette.secondaryText)
        }
        // 화면 끝까지 늘어난 바는 조작감이 둔하다 (F35)
        .frame(maxWidth: DS.Layout.sliderMaxWidth + Layout.sliderLabelAllowance)
    }

    private enum Layout {
        /// 프리뷰 카드 최대 폭 — 이보다 크면 슬라이더가 화면 밖으로 밀린다.
        static let previewMaxWidth: CGFloat = 200
        /// 슬라이더 양옆 라벨("잔잔"·"활발")이 차지하는 폭 여유
        static let sliderLabelAllowance: CGFloat = 96
    }
}

/// 성향 2축용 슬라이더 (F48).
///
/// 시스템 `Slider`는 트랙 아무 데나 톡 치면 손잡이가 **그 자리로 순간이동**한다. 값이 툭
/// 튀어 유동적 무드와 어긋나고, 스크롤하려다 잘못 건드리면 성향이 바뀌어 버린다.
/// 그래서 **손잡이를 눌러 끌 때만** 값이 변하도록 직접 만들었다 — 트랙 탭은 무시한다.
///
/// 드래그는 시작 지점 기준 **상대 이동**이라 손가락과 손잡이가 어긋나지 않는다.
/// 접근성·UI 테스트에는 `accessibilityRepresentation`으로 표준 슬라이더처럼 보인다.
private struct AxisSlider: View {
    @Binding var value: Double
    let label: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragging = false
    /// 드래그를 시작한 순간의 값 — 여기서부터의 이동량만 더한다.
    @State private var startValue: Double = 0

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            // 손잡이 지름만큼 뺀 이동 가능 거리
            let span = max(geo.size.width - Layout.thumb, 1)
            let thumbX = CGFloat(clamped) * span

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: Layout.track)
                Capsule()
                    .fill(.tertiary)
                    .frame(width: thumbX + Layout.thumb / 2, height: Layout.track)

                Circle()
                    .fill(.background)
                    .shadow(color: .black.opacity(Layout.shadowOpacity), radius: dragging ? 5 : 2, y: 1)
                    .frame(width: Layout.thumb, height: Layout.thumb)
                    .scaleEffect(dragging ? Layout.grabScale : 1)
                    .offset(x: thumbX)
                    // 제스처가 **손잡이에만** 붙는다 — 트랙을 눌러도 아무 일이 없다
                    .gesture(drag(span: span))
                    .animation(reduceMotion ? nil : DS.Motion.quick, value: dragging)
            }
            .frame(height: Layout.thumb)
        }
        .frame(height: Layout.thumb)
        .accessibilityRepresentation {
            Slider(value: $value, in: 0...1) { Text(label) }
        }
    }

    private func drag(span: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !dragging {
                    dragging = true
                    startValue = clamped
                }
                let delta = Double(gesture.translation.width / span)
                value = min(max(startValue + delta, 0), 1)
            }
            .onEnded { _ in dragging = false }
    }

    private enum Layout {
        static let track: CGFloat = 6
        static let thumb: CGFloat = 28
        static let grabScale: CGFloat = 1.12
        static let shadowOpacity: Double = 0.18
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
