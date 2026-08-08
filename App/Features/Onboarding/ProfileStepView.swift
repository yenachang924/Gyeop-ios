import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 한 줄 · 이모지 원탭. 전부 선택사항 — 비워도 진행된다.
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCreating = false
    @State private var emojiQuery = ""

    private var visibleEmojis: [EmojiIcon] {
        let query = emojiQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return Array(EmojiCatalog.all.prefix(EmojiCatalog.initialDisplayCount))
        }
        return EmojiCatalog.all.filter { $0.matches(query) }
    }

    var body: some View {
        Form {
            Section {
                Text("유일한 자유 입력이에요. 비워도 괜찮아요.")
                    .font(DS.Typo.subheadline)
                    .foregroundStyle(DS.Palette.secondaryText)
            }

            Section("닉네임") {
                TextField("예나", text: $draft.nickname)
                    .accessibilityIdentifier("onboarding.nickname")
            }

            Section("요즘의 나, 한 줄") {
                TextField("새벽 러닝에 빠졌어요", text: $draft.tagline)
                    .accessibilityIdentifier("onboarding.tagline")
            }

            Section {
                TextField("이모지 검색", text: $emojiQuery)
                    .accessibilityIdentifier("onboarding.emoji.search")
                emojiGrid
            } header: {
                Text("나를 나타내는 이모지 · 선택")
            } footer: {
                Text("안 골라도 진행돼요 — 검색하면 전체 이모지를 볼 수 있어요")
            }

            Section {
                Button {
                    isCreating = true
                    Task {
                        await onCreate()
                        isCreating = false
                    }
                } label: {
                    if isCreating {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    } else {
                        Text("카드 완성")
                            .font(DS.Typo.headline)
                            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    }
                }
                .disabled(isCreating)
                .accessibilityIdentifier("onboarding.createCard")
            }
        }
        .navigationTitle("3 / 3")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emojiGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: DS.minTapTarget), spacing: DS.Spacing.xs)],
            spacing: DS.Spacing.xs
        ) {
            ForEach(visibleEmojis) { icon in
                Button {
                    draft.emoji = (draft.emoji == icon.emoji) ? "" : icon.emoji
                } label: {
                    Text(icon.emoji)
                        .font(DS.Typo.title)
                        .frame(minWidth: DS.minTapTarget, minHeight: DS.minTapTarget)
                        .background(
                            draft.emoji == icon.emoji ? DS.Palette.accent.opacity(0.25) : .clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.chip)
                        )
                        // 이모지 원탭 선택 스프링 — 다른 선택 컨트롤과 같은 결 (quick)
                        .scaleEffect(draft.emoji == icon.emoji ? 1.08 : 1)
                        .animation(reduceMotion ? nil : DS.Motion.quick, value: draft.emoji)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("이모지 \(icon.name)")
                .accessibilityAddTraits(draft.emoji == icon.emoji ? .isSelected : [])
                .accessibilityIdentifier("onboarding.emoji.\(icon.name)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileStepView(draft: .constant(.init())) {}
    }
}
