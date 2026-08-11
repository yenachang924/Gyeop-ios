import SwiftUI
import UIKit

/// 시스템 이모지 키보드로 곧장 열리는 한 글자 입력 필드 (F63 — 연락처 포스터·메시지
/// 그룹 아이콘 방식). 탭하면 이모지 키보드가 뜨고, 무엇을 입력하든 **마지막 이모지
/// 한 글자만** 남는다 — 이모지가 아닌 글자는 버려진다.
///
/// SwiftUI에는 이모지 키보드를 지정하는 API가 없다(`keyboardType`에 이모지 없음) —
/// `UITextInputMode` 오버라이드가 필요한 지점만 UIKit을 래핑한다 (CLAUDE.md 예외 조건).
struct EmojiKeyboardField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.placeholder = "🙂"
        field.font = .systemFont(ofSize: Metrics.glyphSize)
        field.textAlignment = .center
        // 이모지 한 글자 옆에서 깜빡이는 커서는 어색하다 — 선택 UI만 남긴다.
        field.tintColor = .clear
        field.accessibilityIdentifier = "onboarding.emoji"
        field.accessibilityLabel = "나를 나타내는 이모지"

        // 이모지 키보드에는 리턴 키가 없다 — 키보드 위 「완료」로 닫는 길을 만든다 (F45 계승).
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "완료",
                primaryAction: UIAction { [weak field] _ in field?.resignFirstResponder() }
            ),
        ]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        return field
    }

    func updateUIView(_ field: EmojiUITextField, context: Context) {
        if field.text != text {
            field.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = textField.text ?? ""
            let proposed: String
            if let swiftRange = Range(range, in: current) {
                proposed = current.replacingCharacters(in: swiftRange, with: string)
            } else {
                proposed = current + string
            }
            // 필수 항목이라 지워서 비우는 것은 허용하되(다른 이모지로 바꾸는 중간 상태),
            // 남는 값은 항상 "마지막 이모지 한 글자"다.
            let kept = proposed.last(where: \.isEmojiGlyph).map(String.init) ?? ""
            text = kept
            textField.text = kept
            return false
        }
    }

    private enum Metrics {
        /// 카드 마크(24pt)보다 한 급 큰 프리뷰 크기 — 고른 이모지가 또렷이 보이게.
        static let glyphSize: CGFloat = 34
    }
}

/// 첫 응답 시 시스템 이모지 키보드를 우선 선택하는 텍스트 필드.
final class EmojiUITextField: UITextField {
    override var textInputContextIdentifier: String? { "gyeop.emoji" }

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
            ?? super.textInputMode
    }
}

extension Character {
    /// 이모지로 그려지는 글자인지 — 숫자·별표처럼 isEmoji이지만 텍스트로 그려지는
    /// 스칼라(변형 선택자 없는 단일 스칼라)는 제외한다.
    var isEmojiGlyph: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmojiPresentation
            || (scalar.properties.isEmoji && unicodeScalars.count > 1)
    }
}
