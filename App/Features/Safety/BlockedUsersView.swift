import Core
import DataKit
import SwiftUI

struct BlockedUsersView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingUnblock: BlockedUser?
    @State private var failed = false

    var body: some View {
        List {
            Section {
                if model.blockedUsers.isEmpty {
                    Text("차단한 사용자가 없어요")
                }
                ForEach(model.blockedUsers) { user in
                    VStack(alignment: .leading) {
                        Text(user.nickname ?? "차단한 사용자")
                        Button("차단 해제") { pendingUnblock = user }
                            .accessibilityIdentifier("blockedUsers.unblock.\(user.ownerID)")
                    }
                }
            } footer: {
                Text("차단은 이 기기에 적용됩니다. 해제해도 삭제된 카드와 기록은 복구되지 않으며, 이후 다시 교환할 수 있습니다.")
            }
        }
        .navigationTitle("차단한 사용자")
        .task { failed = !(await model.reloadBlockedUsers()) }
        .alert("차단을 해제할까요?", isPresented: Binding(
            get: { pendingUnblock != nil }, set: { if !$0 { pendingUnblock = nil } }
        ), presenting: pendingUnblock) { user in
            Button("해제") {
                Task { failed = !(await model.unblockUser(user.ownerID)) }
            }
            Button("취소", role: .cancel) {}
        } message: { _ in
            Text("이 사용자와 다시 카드를 교환할 수 있게 됩니다. 이전 기록은 복원하지 않아요.")
        }
        .alert("처리하지 못했어요", isPresented: $failed) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("차단 목록을 확인하고 다시 시도해 주세요.")
        }
    }
}
