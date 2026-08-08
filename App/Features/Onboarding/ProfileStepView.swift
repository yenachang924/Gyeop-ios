import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 한 줄 · 이모지 원탭
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: () async -> Void

    @State private var isCreating = false

    private var canCreate: Bool {
        !draft.nickname.trimmingCharacters(in: .whitespaces).isEmpty && !draft.emoji.isEmpty
    }

    var body: some View {
        Form {
            Section("닉네임") {
                TextField("상대가 부를 이름", text: $draft.nickname)
                    .accessibilityIdentifier("onboarding.nickname")
            }

            Section("한 줄") {
                TextField("예: 퇴근하고 클라이밍 가실 분", text: $draft.tagline)
                    .accessibilityIdentifier("onboarding.tagline")
            }

            Section {
                emojiGrid
            } header: {
                Text("대표 이모지 — 하나만 탭")
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
                        Text("카드 만들기")
                            .font(DS.Typo.headline)
                            .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
                    }
                }
                .disabled(!canCreate || isCreating)
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
            ForEach(EmojiCatalog.all) { icon in
                Button {
                    draft.emoji = icon.emoji
                } label: {
                    Text(icon.emoji)
                        .font(DS.Typo.title)
                        .frame(minWidth: DS.minTapTarget, minHeight: DS.minTapTarget)
                        .background(
                            draft.emoji == icon.emoji ? DS.Palette.accent.opacity(0.25) : .clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.chip)
                        )
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
