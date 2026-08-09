import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 한 줄 · 이모지. **셋 다 필수**다 (F28).
/// 처음 만나는 자리에서 카드가 비어 있으면 대화가 시작되지 않는다 — 강제성은
/// 주저함을 덜어주는 장치로 받아들인다 (F4를 한 줄·이모지까지 확대).
///
/// F45 — 이모지 칸 전면 재구성: **검색창을 없앴다.** 텍스트 필드가 있으면 키보드가 뜬 채
/// 그리드를 가리고, 내리기도 어려웠다. 대신 **카테고리 피커 + 그리드**로 137개 전부에
/// 동등하게 닿을 수 있게 했다 — 이모지 선택 경로에 키보드가 아예 등장하지 않는다.
/// 닉네임·한 줄의 키보드는 스크롤로 내려가고, 키보드 위 「완료」로도 닫힌다.
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCreating = false
    /// 선택된 이모지 카테고리. 첫 진입은 관심사 기반 "추천".
    @State private var category: String = Self.recommendedCategory
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case nickname
        case tagline
    }

    /// 관심사에서 뽑아 주는 맞춤 묶음 (F5) — 실제 CSV 카테고리가 아닌 가상 카테고리다.
    private static let recommendedCategory = "추천"

    private var nicknameMissing: Bool {
        draft.nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var taglineMissing: Bool {
        draft.tagline.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var emojiMissing: Bool { draft.emoji.isEmpty }

    private var incomplete: Bool { nicknameMissing || taglineMissing || emojiMissing }

    private var categories: [String] {
        [Self.recommendedCategory] + EmojiCatalog.categories
    }

    /// "추천"은 내가 고른 관심사와 이름이 같은 이모지를 앞에 두고, 나머지는 카탈로그 순서.
    private var visibleEmojis: [EmojiIcon] {
        guard category == Self.recommendedCategory else {
            return EmojiCatalog.icons(in: category)
        }
        let picked = Set(draft.interests)
        let mine = EmojiCatalog.all.filter { picked.contains($0.name) }
        let rest = EmojiCatalog.all.filter { !picked.contains($0.name) }
        return Array((mine + rest).prefix(EmojiCatalog.initialDisplayCount))
    }

    var body: some View {
        Form {
            // 강요 문구 대신 제목으로 (F37) — 무엇을 하면 되는지만 담백하게
            Section {
                Text("칸을 모두 채우면\n카드가 완성돼요")
                    .font(DS.Typo.largeTitle)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, DS.Spacing.s)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .accessibilityAddTraits(.isHeader)
            }

            Section("닉네임") {
                TextField("예나", text: $draft.nickname)
                    .focused($focusedField, equals: .nickname)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .tagline }
                    .accessibilityIdentifier("onboarding.nickname")
            }

            Section("요즘의 나, 한 줄") {
                TextField("새벽 러닝에 빠졌어요", text: $draft.tagline)
                    .focused($focusedField, equals: .tagline)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                    .accessibilityIdentifier("onboarding.tagline")
            }

            Section {
                categoryPicker
                emojiGrid
            } header: {
                Text("나를 나타내는 이모지")
            } footer: {
                Text("하나만 골라 주세요. 묶음을 넘기면 전부 볼 수 있어요.")
            }

            Section {
                Button {
                    // 키보드가 떠 있으면 먼저 내리고 진행한다 (F45)
                    focusedField = nil
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
                // 비활성 이유는 제목이 이미 말한다 — 버튼 아래 보조 문구는 제거 (F37)
                .accessibilityHint(incomplete ? missingHint : "")
                .accessibilityIdentifier("onboarding.createCard")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        // 스크롤만 해도 키보드가 내려간다 (F45)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            // 키보드 위 「완료」 — 스크롤을 모르는 사용자도 확실히 닫을 수 있다 (F45)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { focusedField = nil }
                    .accessibilityIdentifier("onboarding.keyboard.done")
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

    /// 카테고리 피커 — 가로 스크롤 칩. 모든 묶음이 같은 깊이에 있어 동등하게 닿는다 (F45).
    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(categories, id: \.self) { name in
                    Button(name) {
                        // 이모지를 고르러 왔으면 키보드는 필요 없다
                        focusedField = nil
                        category = name
                    }
                    .font(DS.Typo.footnote)
                    .buttonStyle(.plain)
                    .foregroundStyle(category == name ? DS.Palette.onSelection : .secondary)
                    .padding(.horizontal, DS.Spacing.s)
                    .frame(minHeight: DS.minTapTarget)
                    .background(
                        category == name ? DS.Palette.selection : .clear,
                        in: Capsule()
                    )
                    .accessibilityAddTraits(category == name ? .isSelected : [])
                    .accessibilityIdentifier("onboarding.emoji.category.\(name)")
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: DS.Spacing.m, bottom: 0, trailing: 0))
    }

    private var emojiGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: DS.minTapTarget), spacing: DS.Spacing.xs)],
            spacing: DS.Spacing.xs
        ) {
            ForEach(visibleEmojis) { icon in
                Button {
                    focusedField = nil
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
        .animation(reduceMotion ? nil : DS.Motion.quick, value: category)
    }
}

#Preview {
    NavigationStack {
        ProfileStepView(draft: .constant(.init())) {}
    }
}
