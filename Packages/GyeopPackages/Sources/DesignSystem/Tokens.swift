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

    public enum Layout {
        /// 로그인(SIWA) 버튼 최대 폭 — 화면 폭 전체로 퍼지는 문제(1차 시연 지적) 방지.
        public static let signInMaxWidth: CGFloat = 280
        /// 로그인 버튼 높이 (Figma 캡슐 비례)
        public static let signInHeight: CGFloat = 50
        /// 하단 고정 주요 액션 버튼 높이 (F40 — 애플 순정 하단 액션 관습)
        public static let primaryActionHeight: CGFloat = 50
        /// 카드 상세(플립) 카드 최대 폭 (F54 — 시안 62% 폭에서 +20% 상향 지시 반영)
        public static let cardDetailMaxWidth: CGFloat = 300
        /// 홈("나의 카드")의 내 카드 최대 폭 (F62 — F61의 250에서 소유자 지시로 +20%)
        public static let homeMyCardMaxWidth: CGFloat = 300
        /// 하단 페이드 바 전체 높이 (F70) — 버튼(50)과 여백을 덮고도 위로 ~90pt 더
        /// 올라가야 "바"가 아니라 콘텐츠가 아래로 스며드는 쉐이딩으로 읽힌다.
        public static let bottomFadeHeight: CGFloat = 220
    }

    public enum Palette {
        // U1 아트 디렉션 (2026-08-09): 브랜드 색은 POSTECH Red 하나. 빨강은 희소해야 귀하다 —
        // 쓰는 곳은 "겹 성립" 순간(success·GyeopMomentView 링)과 프라이머리 CTA(전역 tint를
        // 타는 .borderedProminent)뿐. 선택 상태·크롬은 무채, 겹침 하이라이트는 overlap 3값.
        // 한 화면에 액센트 빨강이 3곳 이상 보이면 실패로 간주하고 덜어낸다.

        /// 브랜드 액센트 — POSTECH Red. F26(2026-08-09)에서 채도를 올렸다: 웰컴 화면이
        /// 흰 바탕에 로고 타입 하나로 서는 구성이 되면서 이전 값이 탁하게 읽혔다.
        /// 라이트 #A80C4E: hue 유지(≈334°), 채도 0.85→0.93. 흰 배경 대비 7.4:1.
        /// 다크 #ED4279: 채도 0.64→0.72·명도 상향. 다크 표면 #1C1C1E 대비 4.6:1 (AA 유지).
        public static let accent = dynamic(light: 0xA80C4E, dark: 0xED4279)

        /// POSTECH 라운지 골드 — 웰컴 소제 등 액센트를 보조하는 온기.
        /// 라이트는 원색 #DABA65를 그대로 쓰면 흰 배경 대비 1.9:1로 읽히지 않아,
        /// 같은 hue를 어둡게 눌러 4.9:1을 확보했다. 다크는 원색 그대로(대비 10:1).
        public static let brandGold = dynamic(light: 0x8A6E20, dark: 0xDABA65)

        /// 웰컴(로그인 게이트) 전용 배경 — 로고 타입이 서는 무대라 **순백/순흑**이다.
        /// F41: 다크를 #0E0B0D에서 순흑으로 내렸다. 시스템 기본 배경(순흑)과 미세하게 달라
        /// 안전 영역 경계에 띠가 보였다 — 값이 같으면 어긋날 여지 자체가 없다.
        public static let welcomeBackground = dynamic(light: 0xFFFFFF, dark: 0x000000)

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
        /// 겹침 하이라이트 — 텍스트·아이콘 (F26에서 액센트와 함께 채도 상향)
        public static let overlapInk = dynamic(light: 0x7A0A44, dark: 0xF5A9C4)

        /// 유리 표면 반사(sheen) — 구형 배경(F53)이 유리처럼 읽히게 하는 하이라이트.
        /// 광원은 모드와 무관하게 흰빛이라 다이내믹 값이 아니다. 항상 매우 낮은
        /// 불투명도로만 쓴다 — 텍스트 대비 계산에 들어갈 만큼 진해지면 잘못 쓴 것이다.
        public static let glassSheen = Color.white

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

    /// 전부 시스템 텍스트 스타일 매핑 — Dynamic Type 자동 대응.
    ///
    /// **폰트는 전부 Apple 시스템 서체다** (`Font.system` = SF Pro, 한글은 Apple SD Gothic
    /// Neo 폴백). 커스텀 폰트는 쓰지 않는다 — 결정 R3.
    ///
    /// F42 — 굵기 상한: Apple SD Gothic Neo에는 **Bold 위 굵기(Heavy·Black)가 없다.**
    /// `.black`/`.heavy`를 주면 한글만 다른 서체로 폴백되거나 합성돼 SF 계열이 아닌 인상을
    /// 준다. 그래서 한글이 들어가는 스타일의 굵기는 `.bold`를 넘기지 않는다.
    public enum Typo {
        /// 웰컴의 "겹" 로고 타입 (F26 Figma). 로고이므로 Dynamic Type 대상이 아니다 —
        /// 접근성 레이블이 의미를 전달한다.
        public static let wordmark = Font.system(size: 64, weight: .bold, design: .default)
        /// 카드 리빌("이게 나예요") 전용 — largeTitle 한 급 위 (F38). Dynamic Type 대응.
        public static let reveal = Font.system(.largeTitle, design: .default).weight(.bold)
        public static let largeTitle = Font.system(.largeTitle, design: .default).weight(.bold)
        public static let title = Font.system(.title2, design: .default).weight(.semibold)
        /// 목록 섹션 제목 (컬렉션의 "내 카드"·"받은 카드") — 애플 순정 섹션 위계 (F40)
        public static let section = Font.system(.title3, design: .default).weight(.semibold)
        public static let headline = Font.system(.headline, design: .default)
        public static let body = Font.system(.body, design: .default)
        /// 제목 아래 보조 설명 한 줄 (예: 시간·정원 요약)
        public static let subheadline = Font.system(.subheadline, design: .default)
        /// 타임스탬프 등 가장 낮은 위계의 부가 정보
        public static let footnote = Font.system(.footnote, design: .default)
        public static let caption = Font.system(.caption, design: .default)
        /// 하단 주요 액션 아이콘 (F40 컬렉션 맞대기) — 라벨보다 한 급 크게.
        public static let actionIcon = Font.system(.title2, design: .default).weight(.semibold)
        /// 카드 이모지 마크 (F54 — 56pt 히어로에서 좌상단 마크로 강등, 지갑 카드의 로고 자리).
        /// 이모지는 글자가 아니라 픽토그램이라 Dynamic Type 대상에서 제외한다 —
        /// 카드 정보는 접근성 레이블이 전달한다.
        public static let cardMark = Font.system(size: 24)
        /// 카드 뒷면 MBTI 4글자 (F54·F55). 라틴 전용이라 Heavy가 F42의 한글 굵기 상한과
        /// 충돌하지 않는다. 소유자 지시로 시안 52pt에서 한 급 줄인 값.
        public static let mbtiHero = Font.system(size: 44, weight: .heavy, design: .default)
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
        /// F34에서 스프링을 버리고 단조 감속으로 — 실기기에서 미세하게 튕기는 게 보였다.
        public static let cardDeal = Animation.smooth(duration: 0.62)
        /// 화면 요소가 제자리에 내려앉는 등장 (F9 상대 찾는 중 · F12 성향 셀) — 무바운스.
        public static let settle = Animation.smooth(duration: 0.45)
        /// 웰컴 워드마크가 흐릿함에서 또렷해지며 피어오르는 등장 (F26) — 길고 여유 있게.
        public static let wordmark = Animation.smooth(duration: 0.7)
        /// 화면을 떠나며 정리되는 퇴장 (컬렉션으로 전환 등) — 등장보다 짧게.
        public static let depart = Animation.smooth(duration: 0.3)
        /// 관심사를 고를 때 카드가 "물드는" 색 보간 — 축하가 아니라 반영이므로 무바운스.
        public static let dye = Animation.smooth(duration: 0.5)
        /// 카드 플립 (F54) — 유동 무드의 무바운스 회전.
        public static let flip = Animation.smooth(duration: 0.55)
        /// MBTI 알약을 누를 때 배경에 한 번 피었다 지는 색 흐름 (F55).
        public static let bloom = Animation.smooth(duration: 1.4)
        /// MBTI 가운데 글자가 튀어오르며 자리 잡는 등장 (F62) — 선택의 손맛을 주는
        /// 몇 안 되는 유바운스 스프링. 실제 SwiftUI 스프링 기반 (모션 레퍼런스 원칙).
        public static let letterPop = Animation.spring(response: 0.38, dampingFraction: 0.62)
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

// F20 — Liquid Glass 전면 적용 (2026-08-08 소유자 지시). 시스템 컴포넌트(툴바·시트·
// 내비게이션)는 iOS 26 SDK 빌드에서 자동으로 글라스가 되고, 앱이 직접 그리는 버튼은
// 아래 두 헬퍼로 통일한다. 배포 타깃이 iOS 18이라 이전 OS는 기존 스타일로 폴백.
public extension View {
    /// 프라이머리 CTA — Liquid Glass prominent, iOS 26 미만은 borderedProminent.
    @ViewBuilder
    func dsProminentButton() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    /// 보조·미선택 컨트롤 — Liquid Glass, iOS 26 미만은 bordered.
    @ViewBuilder
    func dsGlassButton() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    /// 하단 고정 CTA 뒤의 페이드 바 (F67 → F70에서 키 상향). 위 경계는 투명에서 시작해
    /// 유리(Material)가 점점 짙어지고, 맨 아래는 화면 배경색으로 **불투명하게** 닫힌다.
    /// F70: 페이드가 CTA 높이 안에 갇히면 여전히 "분리된 바"로 읽힌다 — 쉐이딩이
    /// 버튼 위로 충분히(전체 220pt) 올라가도록 바닥 정렬 고정 높이로 그린다.
    /// 지도 앱의 하단 페이드 문법.
    func dsBottomBarFade() -> some View {
        background(alignment: .bottom) {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.6), location: 0.45),
                                .init(color: .black, location: 0.8),
                                .init(color: .black, location: 1),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                LinearGradient(
                    stops: [
                        .init(color: DS.Palette.background.opacity(0), location: 0),
                        .init(color: DS.Palette.background.opacity(0.5), location: 0.75),
                        .init(color: DS.Palette.background, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .frame(height: DS.Layout.bottomFadeHeight)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
    }
}
