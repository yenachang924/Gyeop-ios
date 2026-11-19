import Core
import DesignSystem
import SwiftUI

/// 설정 — 계정 삭제(심사 5.1.1(v) 필수)가 여기 산다. 시스템 Form만 쓴다.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var confirmingDeletion = false
    @State private var deleting = false
    @State private var deletionFailed = false
    @State private var deletionCompleted = false

    var body: some View {
        NavigationStack {
            Form {
                if let card = model.myCard {
                    Section("내 카드") {
                        LabeledContent("닉네임", value: card.nickname)
                        LabeledContent("이모지", value: card.emoji)
                    }
                }

                if let profile = model.myProfile {
                    Section("카드 정보") {
                        LabeledContent("마지막 수정") {
                            Text(profile.lastUpdatedAt, format: .dateTime.year().month().day())
                        }
                    }
                }

                Section {
                    NavigationLink("카드 색 읽는 법") {
                        CardColorGuideView()
                    }
                    .accessibilityIdentifier("settings.cardColorGuide")
                } footer: {
                    Text("카드 색이 무엇을 담는지, 겹의 공식 규칙을 알려드려요.")
                }

                Section("도움말") {
                    NavigationLink("차단한 사용자") {
                        BlockedUsersView()
                    }
                    .accessibilityIdentifier("settings.blockedUsers")
                    if let privacyURL = SupportLinks.privacyPolicy {
                        Link("개인정보처리방침", destination: privacyURL)
                            .accessibilityIdentifier("settings.privacyPolicy")
                    }
                    if let supportURL = SupportLinks.support {
                        Link("고객지원", destination: supportURL)
                            .accessibilityIdentifier("settings.support")
                    }
                    if let communityURL = SupportLinks.community {
                        Link("커뮤니티 이용 안내", destination: communityURL)
                    }
                }

                Section {
                    Button("계정 삭제", role: .destructive) {
                        confirmingDeletion = true
                    }
                    .disabled(deleting)
                    .accessibilityIdentifier("settings.deleteAccount")
                } footer: {
                    Text("카드·겹 기록·로그인 정보가 이 기기에서 모두 삭제됩니다. 되돌릴 수 없어요.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    // 무채 크롬 — 파괴적 액션(systemRed)과 브랜드 레드가 한 화면에서 섞이지 않게 (U1)
                    Button("닫기") { dismiss() }
                        .tint(.primary)
                }
            }
        }
        // F47: 확인 시트(confirmationDialog)는 하단에서 올라와 위치가 어색했다.
        // 되돌릴 수 없는 파괴적 액션이라 **시스템 표준 alert**로 화면 한가운데서 붙잡는다.
        // NavigationStack **바깥**에 붙여야 내비게이션 맥락에 딸려가지 않고 창 중앙에 뜬다.
        .alert("계정을 삭제할까요?", isPresented: $confirmingDeletion) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("카드와 쌓인 겹이 모두 사라집니다. 되돌릴 수 없어요.")
        }
        .alert("삭제하지 못했어요", isPresented: $deletionFailed) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("잠시 후 다시 시도해 주세요.")
        }
        .alert("이 기기의 데이터를 삭제했어요", isPresented: $deletionCompleted) {
            Button("Apple 연결 해제 안내") {
                if let helpURL = SupportLinks.appleAuthorization {
                    openURL(helpURL)
                }
                Task { await finishDeletion() }
            }
            Button("완료") {
                Task { await finishDeletion() }
            }
        } message: {
            Text("Apple로 로그인 연결도 해제하려면 iPhone 설정에서 Apple 계정 > Apple로 로그인 > 겹을 선택해 사용을 중단해 주세요. 이미 상대에게 전달된 카드는 상대 기기에 남을 수 있어요.")
        }
    }

    /// 로컬 삭제 후 Apple의 수동 연결 해제 방법을 알린다 (TN3194).
    private func deleteAccount() async {
        deleting = true
        defer { deleting = false }
        guard await model.deleteAccount() else {
            deletionFailed = true
            return
        }
        deletionCompleted = true
    }

    /// 안내 확인 → 시트 닫힘 → 루트 전환 순서를 유지한다 (F50).
    private func finishDeletion() async {
        dismiss()
        try? await Task.sleep(for: .seconds(Timing.sheetDismiss))
        model.returnToEntry()
    }

    private enum SupportLinks {
        static let privacyPolicy = URL(string: "https://gyeop-support.yenachang924.chatgpt.site/privacy/")
        static let support = URL(string: "https://gyeop-support.yenachang924.chatgpt.site/support/")
        static let community = URL(string: "https://gyeop-support.yenachang924.chatgpt.site/community/")
        static let appleAuthorization = URL(string: "https://support.apple.com/102571")
    }

    private enum Timing {
        /// 시스템 시트가 내려앉는 시간 — 그 뒤에 루트를 크로스페이드한다.
        static let sheetDismiss: TimeInterval = 0.32
    }
}

/// "카드 색 읽는 법" — 카드 색 규칙의 인앱 공식 문서 (F21).
/// 애플 건강 앱의 교육 화면처럼, 앱이 정한 룰을 그대로 알려준다.
/// 원문·단일 진실 원천: docs/card-color-guide.md (같은 파일에 두어 pbxproj 재생성 불필요).
struct CardColorGuideView: View {
    var body: some View {
        List {
            Section {
                Text("카드의 색은 나를 이루는 선택들을 종합적으로 담아낸 것입니다. 고른 관심사, MBTI, 닉네임, 이모지가 모두 섞여 세상에 하나뿐인 색의 흐름이 되고, 같은 입력이면 언제나 같은 카드가 됩니다.")
                    .font(DS.Typo.body)
            }

            Section {
                Text("특정 색이 특정 취미를 뜻하지는 않아요. 색은 그 사람 전체의 인상입니다. 무엇 하나를 바꾸면 카드 전체가 다르게 물들어요. 다음 겹에서, 상대의 색이 어떤 사람일지 상상하며 대화를 시작해 보세요.")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            } header: {
                Text("읽는 법")
            }
        }
        .navigationTitle("카드 색 읽는 법")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
