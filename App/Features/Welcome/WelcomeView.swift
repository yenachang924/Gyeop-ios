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

#Preview {
    WelcomeView()
        .environment(AppModel(cardGenerator: MockCardGenerator(), repository: MockGyeopRepository()))
}
