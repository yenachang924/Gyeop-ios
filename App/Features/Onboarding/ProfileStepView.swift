import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 한 줄 · 이모지. **셋 다 필수**다 (F28).
/// 처음 만나는 자리에서 카드가 비어 있으면 대화가 시작되지 않는다 — 강제성은
/// 주저함을 덜어주는 장치로 받아들인다 (F4를 한 줄·이모지까지 확대).
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCreating = false
    @State private var emojiQuery = ""

    private var nicknameMissing: Bool {
        draft.nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var taglineMissing: Bool {
        draft.tagline.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var emojiMissing: Bool { draft.emoji.isEmpty }

    private var incomplete: Bool { nicknameMissing || taglineMissing || emojiMissing }

    private var visibleEmojis: [EmojiIcon] {
        let query = emojiQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            // 초반 선택(관심사)과 같은 이름의 이모지를 앞으로 — 사용자 맞춤 정렬 (F5).
            // 이름 일치만 승격한다: 카테고리 승격은 1차 노출 16개의 결정성을 깨뜨린다.
            let picked = Set(draft.interests)
            let mine = EmojiCatalog.all.filter { picked.contains($0.name) }
            let rest = EmojiCatalog.all.filter { !picked.contains($0.name) }
            return Array((mine + rest).prefix(EmojiCatalog.initialDisplayCount))
        }
        return EmojiCatalog.all.filter { $0.matches(query) }
    }

    var body: some View {
        Form {
            Section {
                Text("셋 다 채워야 카드가 완성돼요. 처음 만난 사람에게 건넬 얼굴이니까요.")
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
                if visibleEmojis.isEmpty {
                    Text("일치하는 이모지가 없어요")
                        .font(DS.Typo.subheadline)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityIdentifier("onboarding.emoji.empty")
                } else {
                    emojiGrid
                }
            } header: {
                Text("나를 나타내는 이모지")
            } footer: {
                Text("하나만 골라 주세요. 검색하면 전체 이모지를 볼 수 있어요.")
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
                // 글라스 CTA (F20) — 다른 화면의 프라이머리 버튼과 같은 결
                .dsProminentButton()
                .disabled(isCreating || incomplete)
                .accessibilityIdentifier("onboarding.createCard")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                if incomplete {
                    Text(missingHint)
                        .font(DS.Typo.footnote)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .accessibilityIdentifier("onboarding.createCard.hint")
                }
            }
        }
        .animation(reduceMotion ? nil : DS.Motion.quick, value: incomplete)
        .navigationTitle("3 / 3")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 무엇이 비었는지 알려준다 — 비활성 버튼만 두면 이유를 알 수 없다.
    private var missingHint: String {
        var missing: [String] = []
        if nicknameMissing { missing.append("닉네임") }
        if taglineMissing { missing.append("한 줄") }
        if emojiMissing { missing.append("이모지") }
        return "\(missing.joined(separator: " · "))를 채우면 카드가 완성돼요"
    }

    private var emojiGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: DS.minTapTarget), spacing: DS.Spacing.xs)],
            spacing: DS.Spacing.xs
        ) {
            ForEach(visibleEmojis) { icon in
                Button {
                    // 필수 항목이므로 같은 이모지를 다시 눌러도 해제되지 않는다 (F28)
                    draft.emoji = icon.emoji
                } label: {
                    Text(icon.emoji)
                        .font(DS.Typo.title)
                        .frame(minWidth: DS.minTapTarget, minHeight: DS.minTapTarget)
                        .background(
                            // 선택 표시는 무채 — 이모지 자체가 색을 갖고 있다 (U1 원칙 1)
                            draft.emoji == icon.emoji ? DS.Palette.selection.opacity(0.25) : .clear,
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
