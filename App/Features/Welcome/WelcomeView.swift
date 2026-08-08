import AuthenticationServices
import Core
import DesignSystem
import SwiftUI

/// 로그인 게이트 — Sign in with Apple 하나뿐이다 (심사 4.8: 유일한 로그인 수단이 SIWA면 충족).
/// 자격 증명 해석·토큰 저장은 AppModel(조립부)로 넘긴다.
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    @State private var failed = false

    var body: some View {
        // 타이틀·소제는 화면 정중앙(1차 시연 지시), 로그인은 하단 — 흑백 상태 유지.
        ZStack {
            VStack(spacing: DS.Spacing.s) {
                Text("겹")
                    .font(DS.Typo.largeTitle)
                Text("아이폰을 맞대면, 만남이 쌓입니다")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("겹. 아이폰을 맞대면, 만남이 쌓입니다")

            VStack(spacing: DS.Spacing.s) {
                Spacer()

                if failed {
                    Text("로그인하지 못했어요. 다시 시도해 주세요.")
                        .font(DS.Typo.footnote)
                        .foregroundStyle(DS.Palette.secondaryText)
                }

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handle(result)
                }
                // 풀블리드로 퍼지지 않게 폭을 묶는다 (1차 시연: "칸이 넓다")
                .frame(maxWidth: DS.Layout.signInMaxWidth, minHeight: DS.minTapTarget)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("welcome.signInWithApple")
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.background)
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
