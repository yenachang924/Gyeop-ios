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
                    NavigationLink("카드 색 읽는 법") {
                        CardColorGuideView()
                    }
                    .accessibilityIdentifier("settings.cardColorGuide")
                } footer: {
                    Text("색이 성향을 어떻게 담는지, 겹의 공식 규칙을 알려드려요.")
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

/// "카드 색 읽는 법" — 색 → 성향 유추 규칙의 인앱 공식 문서 (F21).
/// 애플 건강 앱의 교육 화면처럼, 앱이 정한 룰을 그대로 알려준다.
/// 원문·단일 진실 원천: docs/card-color-guide.md (같은 파일에 두어 pbxproj 재생성 불필요).
struct CardColorGuideView: View {
    private struct Rule: Identifiable {
        let signal: String
        let reading: String
        var id: String { signal }
    }

    private static let rules: [Rule] = [
        Rule(signal: "활발", reading: "색이 넓게 퍼져요. 다채로운 결"),
        Rule(signal: "잔잔", reading: "색이 좁게 모여요. 차분한 결"),
        Rule(signal: "실외", reading: "밝은 결. 볕이 든 듯 맑아요"),
        Rule(signal: "실내", reading: "깊은 결. 조명이 낮은 듯 아늑해요"),
    ]

    var body: some View {
        List {
            Section {
                Text("카드의 색은 한 사람의 취미와 성향을 종합적으로 담아낸 것입니다. 고른 관심사, 이름, 한 줄, 이모지가 모두 섞여 세상에 하나뿐인 일곱 빛깔이 되고, 같은 입력이면 언제나 같은 카드가 됩니다.")
                    .font(DS.Typo.body)
            }

            Section("색의 결이 말하는 것") {
                ForEach(Self.rules) { rule in
                    LabeledContent(rule.signal, value: rule.reading)
                }
            }

            Section {
                Text("색이 다채롭게 일렁이면 활발한 사람, 한 톤으로 고요하면 잔잔한 사람일 거예요. 밝으면 바깥의 결, 깊으면 실내의 결. 다음 겹에서 색부터 읽어보세요.")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
            } header: {
                Text("읽는 예")
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
