import CardKit
import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택 (최대 5개). 고를 때마다 카드 프리뷰가 물든다.
struct InterestsStepView: View {
    @Binding var selected: [String]
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .disabled(selected.isEmpty)
                .accessibilityIdentifier("onboarding.interests.next")
        }
    }

    /// 프리뷰가 "물드는" 0.5s 전환 — 자리표시 ↔ 카드 스왑과, 선택이 바뀔 때의
    /// MeshGradient 색 보간이 전부 `DS.Motion.dye` 트랜잭션을 탄다.
    private var preview: some View {
        ZStack {
            if selected.isEmpty {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Palette.surface)
                    .aspectRatio(1.6, contentMode: .fit)
                    .overlay {
                        Text("고르는 순간, 카드가 물들어요")
                            .font(DS.Typo.body)
                            .foregroundStyle(DS.Palette.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(DS.Spacing.m)
                    }
                    .transition(.opacity)
                    .accessibilityLabel("카드 미리보기 — 관심사를 고르면 색이 채워져요")
                    .accessibilityIdentifier("onboarding.interests.preview.empty")
            } else {
                CardView(card: previewCard)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .accessibilityLabel("카드 미리보기 — 선택한 관심사로 물든 카드")
                    .accessibilityIdentifier("onboarding.interests.preview.filled")
            }
        }
        .animation(reduceMotion ? nil : DS.Motion.dye, value: selected)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("요즘 나를 이루는 것")
                .font(DS.Typo.largeTitle)
            Text("최대 \(UserProfile.maxInterests)개 — 이 선택이 곧 카드의 색이 됩니다")
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
                    .buttonStyle(.borderedProminent)
                    .tint(DS.Palette.selection)
            } else {
                chipButton(icon, isSelected: false)
                    .buttonStyle(.bordered)
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
