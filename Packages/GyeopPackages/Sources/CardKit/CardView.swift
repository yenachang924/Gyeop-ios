import Core
import DesignSystem
import Foundation
import SwiftUI

/// 정체성 카드 렌더. 앱에서 커스텀 비주얼이 허용된 유일한 컴포넌트 (CLAUDE.md UI 원칙).
///
/// 시드 → 비주얼 결정성 계약은 `CardVisual`에 있다. 질감은 결정 R2에서
/// "그레인 없음"으로 확정 — `cardTexture(_:)`의 항등 변환이 곧 최종 스펙이다.
///
/// 카드 면은 이모지·이름·한줄평만 담는다 (F2) — 관심사는 나열하지 않고 카드의 색으로
/// 표현한다. 겹 성립 순간에는 `overlap`으로 겹치는 관심사가 카드 하단 알약 줄에 뜬다 (F3).
public struct CardView: View {
    private let card: CardSnapshot
    private let overlap: [String]
    private let stirToken: Int
    /// 메시에 넣을 25색. **init에서 한 번만 계산한다** (F49).
    /// 이전에는 `body` 안, 그것도 `KeyframeAnimator` 콘텐츠 클로저 안에서 만들었다 —
    /// 그 클로저는 stir 애니메이션 동안 **매 프레임** 다시 불린다. `CardVisual` 생성은
    /// sha256 기반 PRNG + 색마다 대비 보정 루프(`pow` 반복)라 프레임 예산을 갉아먹었다.
    private let meshColors: [Color]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - overlap: 겹 성립 순간에만 전달 — 카드 하단 알약 줄로 표시된다 (F3).
    ///   - stirToken: 값이 바뀔 때마다 메시가 잠깐 일렁였다 가라앉는다 (F11 "섞는 맛").
    ///     최종 상태는 항상 고정 격자 — "같은 입력=같은 카드"의 결정성은 흔들리지 않는다.
    ///   - colorsOverride: 온보딩 2/3 유동 프리뷰 전용 (F17, `CardPreview.QuadrantPalette`).
    ///     저장·표시되는 실제 카드에는 절대 쓰지 않는다 — 시드가 진실이다.
    public init(
        card: CardSnapshot,
        overlap: [String] = [],
        stirToken: Int = 0,
        colorsOverride: [Color]? = nil
    ) {
        self.card = card
        self.overlap = overlap
        self.stirToken = stirToken
        self.meshColors = colorsOverride ?? CardVisual(seed: card.seed).colors
    }

    /// 등간격 제어점 격자 (결정 R2: 5×5). 위치는 고정, 색만 시드가 정한다 —
    /// 위치까지 흔들면 "같은 입력=같은 카드"의 비교 가능성이 흐려진다.
    private static let meshPoints: [SIMD2<Float>] = {
        let n = CardVisual.meshDimension
        return (0..<n).flatMap { row in
            (0..<n).map { column in
                SIMD2(Float(column) / Float(n - 1), Float(row) / Float(n - 1))
            }
        }
    }()

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            if !card.emoji.isEmpty {
                Text(card.emoji)
                    .font(DS.Typo.cardEmoji)
                    .foregroundStyle(.white)
                    .accessibilityLabel("\(card.nickname)의 대표 이모지")
            }

            Spacer(minLength: DS.Spacing.l)

            // 배경(MeshGradient)은 흰 텍스트 대비 4.5:1을 보장하도록 생성되므로
            // (CardVisual) 시스템 컬러 대신 고정 흰색을 쓴다 — 다크·라이트 모드 무관.
            Text(card.nickname)
                .font(DS.Typo.title)
                .foregroundStyle(.white)
            if !card.tagline.isEmpty {
                Text(card.tagline)
                    .font(DS.Typo.body)
                    .foregroundStyle(.white)
            }

            if !overlap.isEmpty {
                OverlapPillRow(items: overlap)
            }
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 고정 0.7 비율은 콘텐츠(닉네임·태그라인·알약)가 자라는 접근성 폰트 크기에서
        // clipShape에 잘린다 — 접근성 크기에서는 비율을 풀고 세로로 자라게 둔다.
        .aspectRatio(dynamicTypeSize.isAccessibilitySize ? nil : 0.7, contentMode: .fit)
        .background {
            // stir(F11): 트리거가 바뀌면 0→1→0으로 일렁이는 위상 하나만 애니메이션하고,
            // 제어점은 그 위상만큼 격자에서 벗어났다 되돌아온다. Reduce Motion은 트리거 고정.
            KeyframeAnimator(initialValue: 0.0, trigger: reduceMotion ? 0 : stirToken) { phase in
                MeshGradient(
                    width: CardVisual.meshDimension,
                    height: CardVisual.meshDimension,
                    points: Self.stirredPoints(phase: phase),
                    colors: meshColors
                )
                .cardTexture()
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.0, duration: Stir.riseDuration)
                    CubicKeyframe(0.0, duration: Stir.settleDuration)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(card.nickname)의 카드. \(card.tagline). 관심사 \(card.interests.joined(separator: ", ")). 성향 \(card.leisureStyle.label)"
        )
    }

    /// 위상(0=정지 격자)만큼 내부 제어점을 밀어낸 좌표. 가장자리 점은 고정해
    /// 메시가 카드 밖으로 벌어지지 않는다. 방향은 점 인덱스로 결정적 — 난수 없음.
    private static func stirredPoints(phase: Double) -> [SIMD2<Float>] {
        guard phase > 0 else { return meshPoints }
        let n = CardVisual.meshDimension
        let amplitude = Float(phase) * Stir.amplitude
        return meshPoints.enumerated().map { index, point in
            let row = index / n
            let column = index % n
            guard row > 0, row < n - 1, column > 0, column < n - 1 else { return point }
            // 황금각 배수 — 인접 점끼리 방향이 겹치지 않는 결정적 분산
            let angle = Double(index) * 2.399963
            return SIMD2(
                point.x + amplitude * Float(cos(angle)),
                point.y + amplitude * Float(sin(angle))
            )
        }
    }
}

/// F11 stir 튜닝 상수 — 값 조정은 여기서만.
private enum Stir {
    /// 제어점 최대 이탈 거리 (0~1 정규 좌표 기준)
    static let amplitude: Float = 0.045
    /// 일렁임이 커지는 구간 길이
    static let riseDuration: TimeInterval = 0.3
    /// 격자로 가라앉는 구간 길이
    static let settleDuration: TimeInterval = 0.45
}

/// 겹 성립 순간 카드 하단의 겹치는 관심사 알약 줄 (F3). 와인 톤(overlap 3값)으로
/// 카드 위에서 분리되고, 하나씩 0.3s 순차 페이드인한다 (결정 R8 유지).
private struct OverlapPillRow: View {
    let items: [String]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        // 카드 폭을 넘치면 다음 줄로 흘린다 — 말줄임(…)을 만들지 않는다 (F2)
        FlowingPillsLayout(spacing: DS.Spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                Text(item)
                    // 12pt 하한 (F36 접근성) — caption(12)에서 footnote(13)로
                    .font(DS.Typo.footnote)
                    .foregroundStyle(DS.Palette.overlapInk)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.xs)
                    .modifier(PillSurface())
                    .fixedSize()
                    .opacity(shown ? 1 : 0)
                    .animation(
                        reduceMotion
                            ? nil
                            : .smooth(duration: DS.Motion.Moment.chipFadeDuration)
                                .delay(Double(index) * DS.Motion.Moment.chipStaggerStep),
                        value: shown
                    )
            }
        }
        .onAppear { shown = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("겹치는 관심사 \(items.joined(separator: ", "))")
    }
}

/// 알약 표면 — iOS 26은 Liquid Glass(와인 톤 틴트)로 카드가 비쳐 보이고 (F20),
/// 이전 OS는 기존 솔리드 배경으로 폴백. 테두리는 두 경로 공통.
private struct PillSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .glassEffect(.regular.tint(DS.Palette.overlapBg), in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Palette.overlapLine))
        } else {
            content
                .background(DS.Palette.overlapBg, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Palette.overlapLine))
        }
    }
}

/// 알약을 가로로 채우다 넘치면 줄을 바꾸는 단순 랩 레이아웃.
private struct FlowingPillsLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, position) in zip(subviews, arrange(proposal: proposal, subviews: subviews).positions) {
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(
        proposal: ProposedViewSize, subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > 0, origin.x + size.width > maxWidth {
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(origin)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, origin.x - spacing)
        }
        return (CGSize(width: totalWidth, height: origin.y + rowHeight), positions)
    }
}

#Preview("샘플 카드") {
    CardView(card: MockData.sampleCards[0])
        .padding()
}

#Preview("겹침 알약") {
    CardView(
        card: MockData.sampleCards[0],
        overlap: ["클라이밍", "보드게임", "커피"]
    )
    .padding()
}
