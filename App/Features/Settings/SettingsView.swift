import Core
import DesignSystem
import SwiftUI

/// 설정 — 계정 삭제(심사 5.1.1(v) 필수)가 여기 산다. 시스템 Form만 쓴다.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingDeletion = false
    @State private var deleting = false
    @State private var deletionFailed = false

    var body: some View {
        NavigationStack {
            Form {
                if let card = model.myCard {
                    Section("내 카드") {
                        LabeledContent("닉네임", value: card.nickname)
                        LabeledContent("이모지", value: card.emoji)
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
            .confirmationDialog(
                "정말 삭제할까요?",
                isPresented: $confirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("계정 삭제", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("카드와 쌓인 겹이 모두 사라집니다.")
            }
            .alert("삭제하지 못했어요", isPresented: $deletionFailed) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("잠시 후 다시 시도해 주세요.")
            }
        }
    }

    private func deleteAccount() async {
        deleting = true
        defer { deleting = false }
        if await model.deleteAccount() {
            dismiss()
        } else {
            deletionFailed = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
