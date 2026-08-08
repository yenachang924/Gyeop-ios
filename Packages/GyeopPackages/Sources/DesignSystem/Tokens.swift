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

        /// 성사·완료 상태. 겹은 "거절이 성립하지 않는 구조"라 실패를 경고색으로 담지 않는다 —
        /// 성사만 액센트로 축하하고, 대기·실패는 전부 중립(secondaryText)으로 처리한다.
        public static let success = accent
        /// 대기·진행중 상태
        public static let pending = secondaryText
        /// 실패 상태(타임아웃·연결 끊김) — 거절이 아니므로 경고색을 쓰지 않는다.
        public static let failure = secondaryText
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
    }
}
