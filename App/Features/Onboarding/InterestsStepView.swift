import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택 (최대 5개). 고를 때마다 카드 프리뷰가 물든다.
struct InterestsStepView: View {
    @Binding var selected: [String]
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// 선택이 바뀔 때마다 +1 — 카드 프리뷰의 stir(F11 "섞는 맛")를 깨운다.
    @State private var stirCount = 0

    /// 아직 성향·닉네임·이모지를 고르기 전이라 중립값으로 시드를 낸다 — 이후 단계에서
    /// 실제 값이 채워지면 같은 규칙(`CardSeed`)으로 다시 계산되어 최종 카드와 이어진다.
    private var previewCard: CardSnapshot {
        CardSnapshot(
            ownerID: "preview",
            seed: CardSeed.hash(
                nickname: "", emoji: "", interests: selected,
                leisureStyle: LeisureStyle(energy: .calm, venue: .indoor)
            ),
            nickname: "",
            tagline: "",
            emoji: "",
            interests: selected,
            leisureStyle: LeisureStyle(energy: .calm, venue: .indoor),
            version: 1,
            createdAt: .now
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                preview
                header
                interestGrid
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Palette.background)
        .navigationTitle("1 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("다음 · \(selected.count)/\(UserProfile.maxInterests)") { onNext() }
                .dsProminentButton()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .disabled(selected.isEmpty)
                .accessibilityIdentifier("onboarding.interests.next")
        }
    }

    /// 프리뷰가 "물드는" 0.5s 전환. 빈 슬롯과 카드가 **같은 비율(0.7)** 이라 자리가 미리
    /// 잡혀 있다 — 첫 선택에서 카드가 튀어나오며 아래 컨텐츠를 밀어내던 문제를 없앤다(F27).
    /// 전환도 스케일 없이 크로스페이드만 — 자리는 그대로 두고 내용만 바뀐다.
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(DS.Palette.secondaryText.opacity(DS.Opacity.disabled))
                .overlay {
                    Text("고르는 순간, 카드가 물들어요")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(DS.Spacing.m)
                }
                .frame(minHeight: Self.placeholderMinHeight)
                .opacity(selected.isEmpty ? 1 : 0)
                .accessibilityHidden(!selected.isEmpty)
                .accessibilityLabel("카드 미리보기, 관심사를 고르면 색이 채워져요")
                .accessibilityIdentifier("onboarding.interests.preview.empty")

            CardView(card: previewCard, stirToken: stirCount)
                .opacity(selected.isEmpty ? 0 : 1)
                .accessibilityHidden(selected.isEmpty)
                .accessibilityLabel("카드 미리보기, 선택한 관심사로 물든 카드")
                .accessibilityIdentifier("onboarding.interests.preview.filled")
        }
        // 두 상태 공통 비율 — 이 한 줄이 레이아웃 점프를 막는다.
        // 접근성 폰트 크기에서는 CardView가 비율을 풀고 세로로 자라므로 여기서도 푼다
        // (그대로 두면 자란 카드가 잘린다).
        .aspectRatio(
            dynamicTypeSize.isAccessibilitySize ? nil : Self.previewAspectRatio,
            contentMode: .fit
        )
        .animation(reduceMotion ? nil : DS.Motion.dye, value: selected)
        .onChange(of: selected) { stirCount += 1 }
    }

    /// CardView의 고정 비율과 같은 값 — 빈 슬롯이 카드의 자리를 정확히 예약한다.
    private static let previewAspectRatio: CGFloat = 0.7
    /// 접근성 폰트 크기에서 비율이 풀렸을 때 빈 슬롯이 납작해지지 않도록.
    private static let placeholderMinHeight: CGFloat = 220

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("요즘 나를 이루는 것")
                .font(DS.Typo.largeTitle)
            Text("최대 \(UserProfile.maxInterests)개, 이 선택이 곧 카드의 색이 됩니다")
                .font(DS.Typo.body)
                .foregroundStyle(DS.Palette.secondaryText)
        }
    }

    private var interestGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 104), spacing: DS.Spacing.s)],
            spacing: DS.Spacing.s
        ) {
            ForEach(EmojiCatalog.all) { icon in
                interestChip(icon)
            }
        }
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
            HStack(spacing: DS.Spacing.xs) {
                Text(icon.emoji)
                Text(icon.name)
                    .font(DS.Typo.body)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? DS.Palette.onSelection : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
    }
}

#Preview {
    NavigationStack {
        InterestsStepView(selected: .constant(["클라이밍"])) {}
    }
}
