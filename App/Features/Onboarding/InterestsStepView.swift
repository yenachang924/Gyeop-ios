import Core
import DesignSystem
import SwiftUI

/// 온보딩 1/3 — 관심사 선택 (최대 5개)
struct InterestsStepView: View {
    @Binding var selected: [String]
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                header
                interestGrid
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Palette.background)
        .navigationTitle("1 / 3")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("다음") { onNext() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.m)
                .disabled(selected.isEmpty)
                .accessibilityIdentifier("onboarding.interests.next")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("관심사를 골라주세요")
                .font(DS.Typo.largeTitle)
            Text("최대 \(UserProfile.maxInterests)개 — 겹치는 관심사가 첫 대화가 됩니다")
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

        return Button {
            if isSelected {
                selected.removeAll { $0 == icon.name }
            } else if !isFull {
                selected.append(icon.name)
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Text(icon.emoji)
                Text(icon.name)
                    .font(DS.Typo.body)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? DS.Palette.accent : .secondary)
        .disabled(!isSelected && isFull)
        .accessibilityLabel("관심사 \(icon.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.interest.\(icon.name)")
    }
}

#Preview {
    NavigationStack {
        InterestsStepView(selected: .constant(["클라이밍"])) {}
    }
}
