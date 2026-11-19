import Core
import DesignSystem
import SwiftUI

struct CardReportView: View {
    let card: CardSnapshot
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var reason = ""
    @State private var failed = false

    private var draft: CardReportDraft? {
        try? CardReportDraft(card: card, reason: reason)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("신고 사유") {
                    TextEditor(text: $reason)
                        .frame(minHeight: DS.minTapTarget * 3)
                        .accessibilityLabel("신고 사유")
                        .accessibilityIdentifier("report.reason")
                    Text("\(reason.count)/\(CardReportDraft.maximumReasonLength)")
                        .font(DS.Typo.footnote)
                }
                Section("수신자") {
                    Text(CardReportDraft.supportEmail).textSelection(.enabled)
                    if let communityURL = URL(string: "https://gyeop-support.yenachang924.chatgpt.site/community/") {
                        Link("커뮤니티 이용 안내", destination: communityURL)
                    }
                }
                Section("함께 전달되는 카드 정보") {
                    LabeledContent("닉네임", value: card.nickname)
                    LabeledContent("지금의 나", value: card.currentStatus)
                    Text("로컬 사용자 ID: \(card.ownerID)")
                        .font(DS.Typo.footnote)
                        .textSelection(.enabled)
                }
                if let draft {
                    Section("전송할 내용 미리보기") {
                        Text(draft.body).font(DS.Typo.footnote).textSelection(.enabled)
                    }
                }
                Section {
                    Button("메일 앱에서 신고 작성") { openDraft() }
                        .disabled(draft == nil)
                        .accessibilityIdentifier("report.openMail")
                } footer: {
                    Text("자동으로 전송하지 않습니다. 메일 앱에서 내용을 확인하고 직접 전송해야 접수됩니다. 비밀번호와 인증번호는 포함하지 마세요.")
                }
            }
            .navigationTitle("카드 신고")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("메일 앱을 열지 못했어요", isPresented: $failed) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("위 수신자 주소와 미리보기 내용을 복사해 이메일로 보내 주세요. 아직 신고가 전송되지 않았어요.")
            }
        }
    }

    private func openDraft() {
        guard let draft else { return }
        openURL(draft.mailtoURL) { accepted in
            if !accepted { failed = true }
        }
    }
}
