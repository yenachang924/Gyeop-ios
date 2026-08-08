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
        // POSTECH 파운데이션 팔레트 확정본(Figma, 2026-08-08) — 기존 indigo 단일 액센트를 대체.
        // 구조 색(배경·표면·보조텍스트)은 시스템 시맨틱을 그대로 둔다 — 브랜드 색은 액센트
        // 모먼트(버튼·헤드라인·선택 상태·카드 앰비언트 배경)에만 집중시킨다.

        /// 브랜드 메인 — POSTECH Red. 버튼·헤드라인·선택 상태.
        public static let accent = postechColor(0xA6_19_55)
        /// 서브 강조 — POSTECH Orange. 제한적으로만 사용(경고색 아님).
        public static let secondaryAccent = postechColor(0xF6_A7_00)
        /// 고급감 포인트 — POSTECH Gold. 아주 좁은 용도(뱃지·하이라이트 테두리 등)로만.
        public static let gold = postechColor(0xDA_BA_65)
        /// 카드 앰비언트 배경 포인트 — Mint Cyan.
        public static let mint = postechColor(0x74_D6_E4)
        /// mint 보조, 깊이감 — Deep Teal.
        public static let teal = postechColor(0x2F_6F_74)

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

        /// 성사·완료 상태. 겹은 "거절이 성립하지 않는 구조"라 실패를 경고색으로 담지 않는다.
        /// accent(레드)는 버튼 등 브랜드 액션에 집중시키고, 성사 축하는 teal(차분한 긍정)로
        /// 분리했다 — 레드를 그대로 "성공"에 쓰면 대부분의 UI 관례상 경고·에러로 오독되기 쉽다.
        public static let success = teal
        /// 대기·진행중 상태
        public static let pending = secondaryText
        /// 실패 상태(타임아웃·연결 끊김) — 거절이 아니므로 경고색을 쓰지 않는다.
        public static let failure = secondaryText
    }

    /// HEX(0xRRGGBB) → Color. POSTECH 팔레트를 시스템 시맨틱과 섞어 쓰기 위한 내부 변환.
    private static func postechColor(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
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
    }

    /// 시스템 컨트롤(Button 등)은 `.disabled(true)`에서 자동으로 흐려지므로 이 토큰이 필요 없다.
    /// 커스텀 합성 뷰는 `.disabled()`가 상호작용만 막고 겉모습은 그대로라, 직접 흐려줄 때 이 값을 쓴다.
    public enum Opacity {
        public static let disabled: Double = 0.4
    }
}

/// 기본 크기에서도 존재감 있는 헤드라인 — largeTitle보다 크고 무겁게, 그러나 여전히
/// `@ScaledMetric`으로 Dynamic Type에 비례 확대된다 (CLAUDE.md "고정 폰트 크기 금지" 준수).
/// 제목·헤드라인급에만 쓴다 — 본문·캡션 등 읽기 콘텐츠에는 쓰지 않는다.
private struct HeroTitleStyle: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 40

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: .heavy))
    }
}

extension View {
    public func heroTitleStyle() -> some View {
        modifier(HeroTitleStyle())
    }
}
