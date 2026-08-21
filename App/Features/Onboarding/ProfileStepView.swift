import Core
import DesignSystem
import SwiftUI

/// 온보딩 3/3 — 닉네임 · 지금의 나 · 이모지. **셋 다 필수**다 (F28).
/// 처음 만나는 자리에서 카드가 비어 있으면 대화가 시작되지 않는다 — 강제성은
/// 주저함을 덜어주는 장치로 받아들인다 (F4를 지금의 나·이모지까지 확대).
///
/// F63 — 이모지 칸을 **연락처 포스터·메시지 그룹 아이콘 방식**으로 (소유자 선택,
/// F45 카테고리 그리드 은퇴): 필드를 탭하면 시스템 이모지 키보드가 바로 열리고,
/// 마지막 이모지 한 글자만 남는다. 137개 카탈로그 제한이 사라진다.
/// 키보드는 스크롤로 내려가고, 키보드 위 「완료」로도 닫힌다 (F45 계승).
struct ProfileStepView: View {
    @Binding var draft: OnboardingDraft
    let onCreate: (ProfileInput) async -> Bool

    @State private var isCreating = false
    @State private var submissionError: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case nickname
        case currentStatus
    }

    private var nicknameMissing: Bool {
        draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentStatusCharacterCount: Int {
        draft.currentStatus.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var currentStatusValidationMessage: String? {
        if currentStatusCharacterCount == 0 { return "지금의 나를 입력해주세요." }
        if currentStatusCharacterCount > ProfileInput.maximumCurrentStatusLength {
            return "지금의 나는 \(ProfileInput.maximumCurrentStatusLength)자 이하로 입력해주세요."
        }
        return nil
    }

    private var emojiMissing: Bool { draft.emoji.isEmpty }

    private var incomplete: Bool { nicknameMissing || currentStatusValidationMessage != nil || emojiMissing }

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
                TextField("예나", text: nicknameBinding)
                    .focused($focusedField, equals: .nickname)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .currentStatus }
                    .accessibilityIdentifier("onboarding.nickname")
            }

            Section("지금의 나") {
                TextField("첫 iOS 앱을 만들고 있어요", text: currentStatusBinding, axis: .vertical)
                    .focused($focusedField, equals: .currentStatus)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                    .lineLimit(1...2)
                    .accessibilityIdentifier("onboarding.currentStatus")
                if let currentStatusValidationMessage {
                    Text(currentStatusValidationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if currentStatusCharacterCount >= 30 {
                    Text("\(currentStatusCharacterCount)/\(ProfileInput.maximumCurrentStatusLength)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text("요즘 가장 많은 시간을 쓰는 일이나 빠져 있는 것을 적어주세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                // 연락처 포스터 방식 (F63): 필드 하나, 탭하면 이모지 키보드.
                EmojiKeyboardField(text: emojiBinding)
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
                    submit()
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
                if let submissionError {
                    Text(submissionError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        // 키보드 닫는 길 (F65 — 「완료」 버튼 전면 은퇴, 시스템 기본만 남긴다):
        // 스크롤로 내려가고(F45), 닉네임·지금의 나는 리턴 키(submitLabel)로 닫히며,
        // 이모지는 담기는 순간 스스로 닫힌다(F64).
        .scrollDismissesKeyboard(.interactively)
        // F46: Form 전체에 `.animation(value:)`를 걸면 안 된다. `incomplete`가 뒤집히는
        // 순간 **폼 안의 모든 행**(이모지 셀 137개 포함)이 위치 애니메이션을 타서 이모지가
        // 칸 밖으로 날아다녔다. 애니메이션은 실제로 변하는 뷰에만 국소적으로 붙인다.
        .navigationTitle("3 / 3")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nicknameBinding: Binding<String> {
        Binding(
            get: { draft.nickname },
            set: { draft = draft.replacing(nickname: $0) }
        )
    }

    private var currentStatusBinding: Binding<String> {
        Binding(
            get: { draft.currentStatus },
            set: { draft = draft.replacing(currentStatus: $0) }
        )
    }

    private var emojiBinding: Binding<String> {
        Binding(
            get: { draft.emoji },
            set: { draft = draft.replacing(emoji: $0) }
        )
    }

    private func submit() {
        do {
            let input = try ProfileInput(
                nickname: draft.nickname,
                currentStatus: draft.currentStatus,
                emoji: draft.emoji,
                interests: draft.interests,
                mbti: draft.mbti
            )
            submissionError = nil
            isCreating = true
            Task {
                let didCreate = await onCreate(input)
                if !didCreate {
                    submissionError = "카드를 저장하지 못했어요. 다시 시도해주세요."
                }
                isCreating = false
            }
        } catch let error as ProfileInputError {
            submissionError = validationMessage(for: error)
        } catch {
            submissionError = "입력 내용을 다시 확인해주세요."
        }
    }

    private func validationMessage(for error: ProfileInputError) -> String {
        switch error {
        case .emptyNickname:
            return "닉네임을 입력해주세요."
        case .emptyCurrentStatus:
            return "지금의 나를 입력해주세요."
        case .currentStatusTooLong(let maximum):
            return "지금의 나는 \(maximum)자 이하로 입력해주세요."
        case .invalidEmoji:
            return "이모지를 하나 골라주세요."
        case .interestCount, .emptyInterest, .duplicateInterest, .unsupportedInterest:
            return "관심사 3개를 다시 선택해주세요."
        }
    }

    /// 무엇이 비었는지 알려준다 — 비활성 버튼만 두면 이유를 알 수 없다.
    private var missingHint: String {
        var missing: [String] = []
        if nicknameMissing { missing.append("닉네임") }
        if currentStatusValidationMessage != nil { missing.append("지금의 나") }
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
        ProfileStepView(draft: .constant(.init())) { _ in true }
    }
}
