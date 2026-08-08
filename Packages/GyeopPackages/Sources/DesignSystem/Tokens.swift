import SwiftUI

/// 디자인 토큰. 뷰 코드는 색·폰트·간격 리터럴을 직접 쓰지 않고 전부 여기서 가져온다 (CLAUDE.md UI 원칙).
/// 값은 시스템 시맨틱을 우선한다 — 다크모드·Dynamic Type·접근성은 시스템이 이긴다.
public enum DS {
    /// 터치 타깃 최소 크기 (HIG)
    public static let minTapTarget: CGFloat = 44

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let chip: CGFloat = 10
        public static let card: CGFloat = 20
    }

    public enum Palette {
        /// 앱 액센트 (겹의 보라 — 두 색이 겹치는 색)
        public static let accent = Color.indigo
        /// 보조 텍스트
        public static let secondaryText = Color.secondary

        #if canImport(UIKit)
        /// 화면 배경
        public static let background = Color(uiColor: .systemGroupedBackground)
        /// 카드·셀 표면
        public static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        #else
        // macOS는 swift test 컴파일 대상일 뿐 실제 UI는 iOS 전용
        public static let background = Color.gray.opacity(0.1)
        public static let surface = Color.gray.opacity(0.05)
        #endif
    }

    /// 전부 시스템 텍스트 스타일 매핑 — Dynamic Type 자동 대응
    public enum Typo {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title2.weight(.semibold)
        public static let headline = Font.headline
        public static let body = Font.body
        public static let caption = Font.caption
    }
}
