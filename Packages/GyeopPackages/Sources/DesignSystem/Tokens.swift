import Foundation
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
        // U1 아트 디렉션 (2026-08-09): 브랜드 색은 POSTECH Red 하나. 빨강은 희소해야 귀하다 —
        // 쓰는 곳은 "겹 성립" 순간(success·GyeopMomentView 링)과 프라이머리 CTA(전역 tint를
        // 타는 .borderedProminent)뿐. 선택 상태·크롬은 무채, 겹침 하이라이트는 overlap 3값.
        // 한 화면에 액센트 빨강이 3곳 이상 보이면 실패로 간주하고 덜어낸다.

        /// 브랜드 액센트 — POSTECH Red. 원색이 아닌 저채도 딥 레드라 글라스 위에서도 가라앉는다.
        /// 라이트 #A61955: 흰 배경 대비 7.3:1 (텍스트로 써도 AA 통과).
        /// 다크 #E0517F: 시스템 레드가 다크에서 명도를 올리듯(#FF3B30→#FF453A) 들어올린 값 —
        /// 다크 표면 #1C1C1E 대비 4.6:1.
        public static let accent = dynamic(light: 0xA61955, dark: 0xE0517F)

        /// 선택 상태(관심사 칩·성향 셀·이모지) 채움 — 무채 잉크. 프로토타입 칩의 눌린 상태
        /// (`--ios-btn` 솔리드)와 같은 관습. 선택을 액센트로 칠하면 칩 5개 선택 시 화면이
        /// 빨강으로 넘치므로 선택은 항상 무채다.
        public static let selection = Color.primary
        /// selection 채움 위 콘텐츠 색 — primary의 반전 (라이트: 밝은 글자, 다크: 어두운 글자).
        #if canImport(UIKit)
        public static let onSelection = Color(uiColor: .systemBackground)
        #else
        public static let onSelection = Color.white
        #endif

        // 겹침 하이라이트 3값 — Figma `overlap/*` 올리브(#E1E7CC/#C6D19E/#45521F)를 액센트와
        // 같은 hue(≈335°)의 웜 레드 패밀리로 재조율 (U1 원칙 2). 액센트와는 명도·채도로 위계를
        // 분리한다 — 하이라이트는 와인 톤, 축하·CTA만 선명한 빨강.
        // 대비(WCAG): ink/bg 라이트 8.9:1 · 다크 9.2:1, ink/화면배경 라이트 9.9:1 · 다크 9.5:1.
        // line은 장식 테두리(비텍스트)라 대비 기준 비대상.

        /// 겹침 하이라이트 — 칩 배경
        public static let overlapBg = dynamic(light: 0xF7E1E8, dark: 0x38121F)
        /// 겹침 하이라이트 — 칩 테두리
        public static let overlapLine = dynamic(light: 0xE3B9C7, dark: 0x5C2438)
        /// 겹침 하이라이트 — 텍스트·아이콘
        public static let overlapInk = dynamic(light: 0x731441, dark: 0xF2AFC6)

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

        /// 성사·완료 상태. 겹은 "거절이 성립하지 않는 구조"라 실패를 경고색으로 담지 않는다 —
        /// 성사만 액센트로 축하하고, 대기·실패는 전부 중립(secondaryText)으로 처리한다.
        /// "겹 성립" 순간이 곧 브랜드 빨강이 허락된 자리다 (U1 원칙 1).
        public static let success = accent
        /// 대기·진행중 상태
        public static let pending = secondaryText
        /// 실패 상태(타임아웃·연결 끊김) — 거절이 아니므로 경고색을 쓰지 않는다.
        public static let failure = secondaryText

        /// 라이트·다크 값 쌍 → Color. 시스템 시맨틱에 없는 브랜드 색만 이 경로로 만든다 —
        /// 구조 색(배경·표면·보조텍스트)은 계속 시스템 시맨틱을 쓴다.
        private static func dynamic(light: UInt32, dark: UInt32) -> Color {
            #if canImport(UIKit)
            return Color(uiColor: UIColor { traits in
                rgb(traits.userInterfaceStyle == .dark ? dark : light)
            })
            #else
            // macOS는 swift test 컴파일 대상일 뿐 — 라이트 값으로 고정
            return Color(
                red: Double((light >> 16) & 0xFF) / 255,
                green: Double((light >> 8) & 0xFF) / 255,
                blue: Double(light & 0xFF) / 255
            )
            #endif
        }

        #if canImport(UIKit)
        private static func rgb(_ hex: UInt32) -> UIColor {
            UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        }
        #endif
    }

    /// 전부 시스템 텍스트 스타일 매핑 — Dynamic Type 자동 대응
    public enum Typo {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title2.weight(.semibold)
        public static let headline = Font.headline
        public static let body = Font.body
        /// 제목 아래 보조 설명 한 줄 (예: 시간·정원 요약)
        public static let subheadline = Font.subheadline
        /// 타임스탬프 등 가장 낮은 위계의 부가 정보
        public static let footnote = Font.footnote
        public static let caption = Font.caption
        /// D-day 등 상시 노출되는 카운터 숫자 — Weather/Fitness/Screen Time처럼 Rounded 디자인,
        /// monospacedDigit으로 자릿수 변화에도 레이아웃이 흔들리지 않는다.
        public static let counter = Font.system(.title, design: .rounded).weight(.heavy).monospacedDigit()
        /// 카드 대표 이모지 (F5 — 카드에서 더 크게). 이모지는 글자가 아니라 픽토그램이라
        /// Dynamic Type 대상에서 제외한다 — 카드 정보는 접근성 레이블이 전달한다.
        public static let cardEmoji = Font.system(size: 56)
    }

    /// 상태 전환 애니메이션 프리셋. 시스템 시트·탭 전환과 같은 계열의 스프링을 재사용해
    /// 커스텀 이징이 이곳저곳에서 제각각 나타나지 않게 한다. Reduce Motion은 호출부에서
    /// `accessibilityReduceMotion` 확인 후 `.linear`/`nil`로 대체한다.
    public enum Motion {
        /// 카드 도착·매칭 성사처럼 "축하할 만한" 전환 — 살짝 튕긴다.
        public static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)
        /// 버튼·토글처럼 잦고 가벼운 반응 — 거의 안 튕긴다.
        public static let quick = Animation.spring(response: 0.2, dampingFraction: 0.9)
        /// 카드 등장(리빌·첫 표시) — 스케일 인과 함께 쓴다. standard보다 한 호흡 길고 여유 있게.
        public static let cardAppear = Animation.spring(response: 0.4, dampingFraction: 0.75)
        /// 카드 딜 인 (F6 — 토스 카드 발급 모티브): 아래에서 떠오르며 틸트가 풀린다.
        /// cardAppear보다 길고, 유동 무드에 맞춰 거의 안 튕긴다.
        public static let cardDeal = Animation.spring(response: 0.55, dampingFraction: 0.85)
        /// 화면 요소가 제자리에 내려앉는 등장 (F9 상대 찾는 중 · F12 성향 셀) — 무바운스.
        public static let settle = Animation.smooth(duration: 0.45)
        /// 관심사를 고를 때 카드가 "물드는" 색 보간 — 축하가 아니라 반영이므로 무바운스.
        public static let dye = Animation.smooth(duration: 0.5)
        /// "겹!" 융합 — 결정 R7: `.smooth` 스프링, response 0.5, 거의 무바운스(단조 감속).
        public static let merge = Animation.smooth(duration: 0.5)
        /// "겹!" 링 파동 1회 — 확장하며 사라진다. 무바운스(파동은 되돌아오지 않는다).
        public static let ringPulse = Animation.smooth(duration: Moment.ringDuration)

        /// "겹!" 순간(융합 → 링 → 워드 → 칩) 타이밍 상수 — 실기기 감각 튜닝 대상 (U2).
        public enum Moment {
            /// 링 파동 시작 — 융합이 착지하는 시점에 맞춘다.
            public static let ringDelay: TimeInterval = 0.45
            /// 링 파동 길이.
            public static let ringDuration: TimeInterval = 0.7
            /// "겹!" 워드 등장 시점.
            public static let wordDelay: TimeInterval = 0.55
            /// 연출 전체 길이 — 이후 겹침 결과를 공개한다 (navigation-map §1: 1.5s).
            public static let total: TimeInterval = 1.5
            /// 겹친 칩 하나의 페이드인 길이 (결정 R8: 0.3s 순차 페이드인).
            public static let chipFadeDuration: TimeInterval = 0.3
            /// 칩 사이 순차 지연 간격.
            public static let chipStaggerStep: TimeInterval = 0.1
        }
    }

    /// 시스템 컨트롤(Button 등)은 `.disabled(true)`에서 자동으로 흐려지므로 이 토큰이 필요 없다.
    /// 커스텀 합성 뷰는 `.disabled()`가 상호작용만 막고 겉모습은 그대로라, 직접 흐려줄 때 이 값을 쓴다.
    public enum Opacity {
        public static let disabled: Double = 0.4
        /// 컬렉션 내 카드 주변 쉬머링 강도 (F7 — "아주 은은하게 4% 정도").
        /// 실기기 체감 튜닝 대상 — 값 조정은 여기서만.
        public static let shimmer: Double = 0.04
    }
}
