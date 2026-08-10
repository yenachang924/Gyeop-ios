import AuthenticationServices
import Core
import DesignSystem
import SwiftUI

/// 로그인 게이트 — Sign in with Apple 하나뿐이다 (심사 4.8: 유일한 로그인 수단이 SIWA면 충족).
/// 자격 증명 해석·토큰 저장은 AppModel(조립부)로 넘긴다.
///
/// 시각은 소유자 Figma 확정본 (F26): 순백/순흑 무대에 "겹" 워드마크(POSTECH Red)와
/// 골드 소제가 정중앙, 로그인은 하단 캡슐. 등장은 워드마크 → 소제 → 버튼 순으로 흐른다.
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var failed = false
    /// 등장 단계 — 0: 없음, 1: 워드마크, 2: 소제, 3: 로그인
    @State private var stage = 0

    var body: some View {
        ZStack {
            VStack(spacing: DS.Spacing.s) {
                Text("겹")
                    .font(DS.Typo.wordmark)
                    .foregroundStyle(DS.Palette.accent)
                    .scaleEffect(stage >= 1 ? 1 : 0.82)
                    .opacity(stage >= 1 ? 1 : 0)
                    .blur(radius: stage >= 1 ? 0 : 6)

                Text("아이폰을 맞대면 쌓이는 만남")
                    .font(DS.Typo.headline)
                    .foregroundStyle(DS.Palette.brandGold)
                    .multilineTextAlignment(.center)
                    .opacity(stage >= 2 ? 1 : 0)
                    .offset(y: stage >= 2 ? 0 : 10)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("겹. 아이폰을 맞대면 쌓이는 만남")

            VStack(spacing: DS.Spacing.s) {
                Spacer()

                // 실패 문구만 페이드로 나타난다 — 애니메이션을 화면 전체에 걸면 워드마크·
                // 버튼까지 함께 움직인다 (F46과 같은 부류의 실수).
                Text("로그인하지 못했어요. 다시 시도해 주세요.")
                    .font(DS.Typo.footnote)
                    .foregroundStyle(DS.Palette.secondaryText)
                    .opacity(failed ? 1 : 0)
                    .animation(reduceMotion ? nil : DS.Motion.quick, value: failed)
                    .accessibilityHidden(!failed)

                // `.continue` = "Continue with Apple". `.signIn`은 로고가 크게 뜨는
                // 레이아웃이라 F33에서 교체했다. 프레임을 **고정**해야 버튼이 남는 공간만큼
                // 부풀지 않는다 (SignInWithAppleButton은 고유 크기가 없다).
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handle(result)
                }
                // 흰 무대에는 검정 캡슐, 검은 무대에는 흰 캡슐 (Figma 확정 + 다크 대조)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(width: DS.Layout.signInMaxWidth, height: DS.Layout.signInHeight)
                .clipShape(Capsule())
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 ? 0 : 18)
                .accessibilityIdentifier("welcome.signInWithApple")
            }
        }
        .padding(DS.Spacing.l)
        // 앱 아이콘의 "겹친 두 원"을 세로로 세운 배경 (F51) — 겹! 순간 연출(R7)과 같은
        // 버티컬 축이라 브랜드 언어가 이어진다. 워드마크는 두 원이 겹치는 자리에 선다.
        .background { WelcomeBackdrop() }
        // `.ignoresSafeArea()`가 없으면 배경이 콘텐츠 영역까지만 칠해져 상태 표시줄·홈
        // 인디케이터 구간에 시스템 배경이 그대로 드러난다 — 화면이 위아래로 갈라져 보이던
        // 원인 (F41). 무대는 화면 전체여야 한다.
        .background(DS.Palette.welcomeBackground.ignoresSafeArea())
        .task { await runEntrance() }
    }

    /// 워드마크가 먼저 피어오르고, 소제와 로그인이 뒤따른다 (F26 애니메이션 개선).
    /// Reduce Motion에서는 전부 즉시 표시.
    private func runEntrance() async {
        guard !reduceMotion else {
            stage = 3
            return
        }
        withAnimation(DS.Motion.wordmark) { stage = 1 }
        try? await Task.sleep(for: .seconds(Entrance.subtitleDelay))
        withAnimation(DS.Motion.settle) { stage = 2 }
        try? await Task.sleep(for: .seconds(Entrance.signInDelay))
        withAnimation(DS.Motion.settle) { stage = 3 }
    }

    private enum Entrance {
        /// 워드마크가 자리 잡은 뒤 소제가 붙는 간격
        static let subtitleDelay: TimeInterval = 0.32
        /// 소제 뒤 로그인 버튼이 올라오는 간격
        static let signInDelay: TimeInterval = 0.22
    }

    private func handle(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8)
            else {
                failed = true
                return
            }
            failed = false
            model.completeSignIn(identityToken: token)
        case .failure:
            // 사용자 취소 포함 — 조용히 게이트에 남는다
            failed = true
        }
    }
}

/// 로그인 이전 화면의 배경 (F51 → F53) — 앱 아이콘의 겹친 두 원을 **세로로** 세운 뒤,
/// 애플 유동 배경화면처럼 **천천히 일렁이는 구형 글라스**로 다시 만들었다.
///
/// 구는 방사 그라디언트다. 알파가 반지름 끝에서 0이 되므로 **테두리가 남지 않는다** —
/// 소유자 요청("구형이 뚜렷하진 않아도")의 핵심이 여기다. 블러는 형태를 뭉개는 용도가
/// 아니라 광택을 퍼뜨리는 용도라 F51(60)보다 얕다.
///
/// 위 = 브랜드 레드, 아래 = 골드·올리브, 만나는 띠 = 겹 칩과 같은 와인(`overlapInk`).
/// 세 구가 **서로 어긋난 주기**로 오르내려 패턴이 반복으로 읽히지 않는다.
private struct WelcomeBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 일렁임의 유일한 상태. false↔true 사이를 무한 왕복하고, 그 사이를
    /// **변환(offset·scale)만** 보간한다 — 프레임마다 색을 다시 만들지 않는다 (F49).
    @State private var drifting = false

    var body: some View {
        GeometryReader { geo in
            let diameter = geo.size.width * Layout.diameterRatio
            let gap = diameter * Layout.overlapRatio

            ZStack {
                orb(DS.Palette.accent, diameter: diameter)
                    .offset(
                        x: drifting ? Layout.sway : -Layout.sway,
                        y: -gap - (drifting ? Layout.rise : -Layout.rise)
                    )
                    .scaleEffect(drifting ? Layout.swellHigh : Layout.swellLow)
                    .animation(loop(Layout.upperPeriod), value: drifting)

                orb(DS.Palette.brandGold, diameter: diameter)
                    .offset(
                        x: drifting ? -Layout.sway : Layout.sway,
                        y: gap + (drifting ? Layout.rise : -Layout.rise)
                    )
                    .scaleEffect(drifting ? Layout.swellLow : Layout.swellHigh)
                    .animation(loop(Layout.lowerPeriod), value: drifting)

                // 두 구가 만나는 자리 — "겹" 그 자체의 색이 유리처럼 배어난다.
                // 화면 중앙(워드마크 자리)이라 지름을 줄이고 불투명도를 더 낮춘다.
                orb(DS.Palette.overlapInk, diameter: diameter * Layout.bandRatio)
                    .scaleEffect(drifting ? Layout.bandHigh : Layout.bandLow)
                    .opacity(Layout.bandOpacity)
                    .animation(loop(Layout.bandPeriod), value: drifting)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .blur(radius: Layout.blur)
            // 세 구를 먼저 합성한 뒤 한 번만 흐리고 한 번만 옅게 만든다.
            .compositingGroup()
            .opacity(colorScheme == .dark ? Layout.darkOpacity : Layout.lightOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { drifting = true }
    }

    /// 구 하나 — 중심이 위로 치우친 방사 그라디언트(광원)에 흰 반사 한 겹.
    /// 끝 정지점은 `.clear`가 아니라 `color.opacity(0)`이다. `.clear`는 알파 0인
    /// **검정**이라 보간 중간이 탁하게 죽는다 — 같은 색의 알파만 떨어뜨려야 맑게 사라진다.
    private func orb(_ color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(Layout.midAlpha), color.opacity(0)],
                    center: Layout.lightSource,
                    startRadius: 0,
                    endRadius: diameter * Layout.falloff
                )
            )
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DS.Palette.glassSheen.opacity(Layout.sheenAlpha),
                                DS.Palette.glassSheen.opacity(0),
                            ],
                            center: Layout.sheenCenter,
                            startRadius: 0,
                            endRadius: diameter * Layout.sheenRadius
                        )
                    )
            }
            .frame(width: diameter, height: diameter)
    }

    /// 무한 왕복. Reduce Motion이면 애니메이션이 없어 초기 위치에 고정된다.
    private func loop(_ duration: TimeInterval) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration).repeatForever(autoreverses: true)
    }

    /// 배경 튜닝 — 값 조정은 여기서만. 불투명도는 텍스트 대비가 정한 상한이다.
    private enum Layout {
        static let diameterRatio: CGFloat = 0.92
        /// 두 구 중심이 화면 중앙에서 떨어진 거리 (지름 배수). 작을수록 많이 겹친다.
        static let overlapRatio: CGFloat = 0.32
        /// 알파가 0이 되는 지점 = 원의 가장자리. 그래서 테두리가 보이지 않는다.
        static let falloff: CGFloat = 0.5
        /// 반지름 절반 지점의 알파 — 핵이 뭉치는 정도
        static let midAlpha: Double = 0.55
        /// 광원 위치 (구 좌표계). 중앙보다 위·왼쪽이라 아래가 그늘처럼 남는다.
        static let lightSource = UnitPoint(x: 0.42, y: 0.36)

        static let sheenCenter = UnitPoint(x: 0.34, y: 0.26)
        static let sheenRadius: CGFloat = 0.34
        static let sheenAlpha: Double = 0.32

        /// 형태를 뭉개는 게 아니라 광택을 퍼뜨리는 용도 — F51(60)보다 얕다.
        static let blur: CGFloat = 34
        /// **대비 상한.** 소제(골드)가 골드 구의 꼬리 위에 앉으므로 더 올리면 4.5:1이 깨진다.
        static let lightOpacity: Double = 0.20
        static let darkOpacity: Double = 0.34

        /// 일렁임 — 세로 진폭이 가로보다 크다 (버티컬 축이 브랜드 언어다)
        static let rise: CGFloat = 22
        static let sway: CGFloat = 12
        static let swellLow: CGFloat = 0.94
        static let swellHigh: CGFloat = 1.06
        /// 서로 나누어떨어지지 않는 주기 — 겹쳐도 같은 그림이 되돌아오지 않는다
        static let upperPeriod: TimeInterval = 13
        static let lowerPeriod: TimeInterval = 17
        static let bandPeriod: TimeInterval = 21

        static let bandRatio: CGFloat = 0.66
        static let bandLow: CGFloat = 0.88
        static let bandHigh: CGFloat = 1.1
        static let bandOpacity: Double = 0.5
    }
}

#Preview {
    WelcomeView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
