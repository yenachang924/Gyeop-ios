import Core
import DesignSystem
import Foundation
import SwiftUI

/// 정체성 카드 렌더 (앞면). 앱에서 커스텀 비주얼이 허용된 유일한 컴포넌트 (CLAUDE.md UI 원칙).
///
/// 시드 → 비주얼 결정성 계약은 `CardVisual`에 있다.
///
/// F54 (카드 리디자인 라운드): 카드는 **유리 카드**다 — 위쪽 반사 한 겹과 유리 테두리로
/// 마감한다. 앞면의 히어로는 색(오라 그라데이션) 하나: 이모지는 56pt 히어로에서
/// **좌상단 마크**(지갑 카드의 로고 자리)로 강등됐고(F5 개정), 텍스트는 오라가 밝아
/// 흰색 → **잉크**(`CardVisual.inkColor`)로 바뀌었다. 관심사·MBTI는 뒷면(`CardBackView`) 몫이다.
/// 겹 성립 순간에는 `overlap`으로 겹치는 관심사가 카드 하단 알약 줄에 뜬다 (F3).
public struct CardView: View {
    private let card: CardSnapshot
    private let overlap: [String]
    private let stirToken: Int
    /// 메시에 넣을 25색. **init에서 한 번만 계산한다** (F49).
    private let meshColors: [Color]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - overlap: 겹 성립 순간에만 전달 — 카드 하단 알약 줄로 표시된다 (F3).
    ///   - stirToken: 값이 바뀔 때마다 메시가 잠깐 일렁였다 가라앉는다 (F11 "섞는 맛").
    ///     최종 상태는 항상 고정 격자 — "같은 입력=같은 카드"의 결정성은 흔들리지 않는다.
    public init(
        card: CardSnapshot,
        overlap: [String] = [],
        stirToken: Int = 0
    ) {
        self.card = card
        self.overlap = overlap
        self.stirToken = stirToken
        self.meshColors = CardVisual(seed: card.seed).colors
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
                    .font(DS.Typo.cardMark)
                    .accessibilityLabel("\(card.nickname)의 대표 이모지")
            }

            Spacer(minLength: DS.Spacing.l)

            // 오라 배경은 잉크 대비 4.5:1을 보장하도록 생성된다 (CardVisual F56) —
            // 카드는 라이트·다크 동일(R2)이므로 시스템 컬러 대신 고정 잉크를 쓴다.
            Text(card.nickname)
                .font(DS.Typo.title)
            if !card.tagline.isEmpty {
                Text(card.tagline)
                    .font(DS.Typo.body)
            }

            if !overlap.isEmpty {
                OverlapPillRow(items: overlap)
            }
        }
        .foregroundStyle(CardVisual.inkColor)
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
        .cardGlassFinish()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(frontAccessibilityLabel)
    }

    private var frontAccessibilityLabel: String {
        var parts = ["\(card.nickname)의 카드"]
        if !card.tagline.isEmpty { parts.append(card.tagline) }
        if !card.interests.isEmpty { parts.append("관심사 \(card.interests.joined(separator: ", "))") }
        if let mbti = card.mbti { parts.append("MBTI \(mbti.code)") }
        return parts.joined(separator: ". ")
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

/// 카드 뒷면 — 반투명 유리 면에 카드의 hue가 비쳐 보인다 (F54: "완전 하얀색이 아니라").
/// 히어로는 무채 MBTI 4글자 하나뿐이고 아래 바(구분선)는 없다 — 담백하게 (소유자 지시).
/// 관심사는 유리 칩으로 내려앉는다. 텍스트는 시스템 primary — 라이트 검정 / 다크 흰색.
public struct CardBackView: View {
    private let card: CardSnapshot
    private let meshColors: [Color]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(card: CardSnapshot) {
        self.card = card
        self.meshColors = CardVisual(seed: card.seed).colors
    }

    public var body: some View {
        VStack(spacing: DS.Spacing.m) {
            if let mbti = card.mbti {
                Text(mbti.code)
                    .font(DS.Typo.mbtiHero)
                    .accessibilityLabel("MBTI \(mbti.code)")
            }

            if !card.interests.isEmpty {
                interestChips
            }
        }
        .foregroundStyle(.primary)
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(dynamicTypeSize.isAccessibilitySize ? nil : 0.7, contentMode: .fit)
        .background {
            // 앞면과 같은 오라를 깔고 유리(Material)를 덮는다 — 뒤집어도 "같은 카드"라는
            // 감각이 hue로 이어진다. Material이 라이트·다크를 알아서 탄다.
            ZStack {
                MeshGradient(
                    width: CardVisual.meshDimension,
                    height: CardVisual.meshDimension,
                    points: Self.gridPoints,
                    colors: meshColors
                )
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .cardGlassFinish()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(backAccessibilityLabel)
    }

    private var interestChips: some View {
        FlowingPillsLayout(spacing: DS.Spacing.xs) {
            ForEach(card.interests, id: \.self) { interest in
                Text(interest)
                    .font(DS.Typo.footnote)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(.quaternary))
                    .fixedSize()
            }
        }
    }

    private var backAccessibilityLabel: String {
        var parts = ["\(card.nickname)의 카드 뒷면"]
        if let mbti = card.mbti { parts.append("MBTI \(mbti.code)") }
        if !card.interests.isEmpty { parts.append("관심사 \(card.interests.joined(separator: ", "))") }
        return parts.joined(separator: ". ")
    }

    private static let gridPoints: [SIMD2<Float>] = {
        let n = CardVisual.meshDimension
        return (0..<n).flatMap { row in
            (0..<n).map { column in
                SIMD2(Float(column) / Float(n - 1), Float(row) / Float(n - 1))
            }
        }
    }()
}

/// 카드 플립 — 앞면(색)과 뒷면(MBTI·관심사)을 탭으로 오간다 (F54).
/// 유동 무드에 맞는 무바운스 회전, Reduce Motion은 회전 없이 즉시 교체.
public struct CardFlipView: View {
    private let card: CardSnapshot
    @State private var isFlipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(card: CardSnapshot) {
        self.card = card
    }

    public var body: some View {
        ZStack {
            CardView(card: card)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.55
                )
            CardBackView(card: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.55
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .onTapGesture {
            withAnimation(reduceMotion ? nil : DS.Motion.flip) {
                isFlipped.toggle()
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("탭하면 카드가 뒤집혀요")
        .accessibilityIdentifier("card.flip")
    }
}

/// 유리 카드 마감 (F54) — 위쪽 반사(sheen) 한 겹 + 유리 테두리. 앞·뒷면 공통.
/// 반사 광원은 모드와 무관하게 흰빛(`DS.Palette.glassSheen`)이다.
private struct CardGlassFinish: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                DS.Palette.glassSheen.opacity(Glass.sheenOpacity),
                                .clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(DS.Palette.glassSheen.opacity(Glass.edgeOpacity), lineWidth: 1)
            }
    }
}

private extension View {
    func cardGlassFinish() -> some View {
        modifier(CardGlassFinish())
    }
}

/// 유리 마감 튜닝 상수 — 값 조정은 여기서만 (실기기 체감 대상).
private enum Glass {
    /// 위쪽 반사 강도 — 오라를 가리지 않는 은은한 광택.
    static let sheenOpacity: Double = 0.28
    /// 유리 테두리 강도.
    static let edgeOpacity: Double = 0.45
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
struct FlowingPillsLayout: Layout {
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

#Preview("카드 플립") {
    CardFlipView(card: MockData.sampleCards[0])
        .padding(DS.Spacing.xl)
}

#Preview("겹침 알약") {
    CardView(
        card: MockData.sampleCards[0],
        overlap: ["클라이밍", "보드게임", "커피"]
    )
    .padding()
}
