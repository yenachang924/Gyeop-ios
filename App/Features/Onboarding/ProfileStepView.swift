import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 한 줄 · 이모지. **셋 다 필수**다 (F28).
/// 처음 만나는 자리에서 카드가 비어 있으면 대화가 시작되지 않는다 — 강제성은
/// 주저함을 덜어주는 장치로 받아들인다 (F4를 한 줄·이모지까지 확대).
///
/// F63 — 이모지 칸을 **연락처 포스터·메시지 그룹 아이콘 방식**으로 (소유자 선택,
/// F45 카테고리 그리드 은퇴): 필드를 탭하면 시스템 이모지 키보드가 바로 열리고,
/// 마지막 이모지 한 글자만 남는다. 137개 카탈로그 제한이 사라진다.
/// 키보드는 스크롤로 내려가고, 키보드 위 「완료」로도 닫힌다 (F45 계승).
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCreating = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case nickname
        case tagline
    }

    private var nicknameMissing: Bool {
        draft.nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var taglineMissing: Bool {
        draft.tagline.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var emojiMissing: Bool { draft.emoji.isEmpty }

    private var incomplete: Bool { nicknameMissing || taglineMissing || emojiMissing }

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
                // 연락처 포스터 방식 (F63): 필드 하나, 탭하면 이모지 키보드.
                EmojiKeyboardField(text: $draft.emoji)
                    .frame(minHeight: Layout.emojiFieldHeight)
            } header: {
                Text("나를 나타내는 이모지")
            } footer: {
                Text("탭해서 하나만 골라 주세요. 고르면 키보드가 닫혀요.")
            }

            Section {
                Button {
                    // 키보드가 떠 있으면 먼저 내리고 진행한다 (F45).
                    // 이모지 필드는 UIKit이라 FocusState 밖 — 첫 응답자를 직접 내린다.
                    focusedField = nil
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
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
        // F46: Form 전체에 `.animation(value:)`를 걸면 안 된다. `incomplete`가 뒤집히는
        // 순간 **폼 안의 모든 행**(이모지 셀 137개 포함)이 위치 애니메이션을 타서 이모지가
        // 칸 밖으로 날아다녔다. 애니메이션은 실제로 변하는 뷰에만 국소적으로 붙인다.
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

    private enum Layout {
        /// 이모지 필드 행 높이 — 34pt 글리프가 여유 있게 앉는다.
        static let emojiFieldHeight: CGFloat = 52
    }
}

#Preview {
    NavigationStack {
        ProfileStepView(draft: .constant(.init())) {}
    }
}
