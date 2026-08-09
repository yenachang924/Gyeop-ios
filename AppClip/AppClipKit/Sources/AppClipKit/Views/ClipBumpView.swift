import DesignSystem
import SwiftUI

/// 6 `bump` — 교환 진행 중. 실기기는 MPC 자동 트리거, 시뮬레이터는 Mock 스크립트가
/// 흘러간다 (navigation-map §1-6 "실앱: MPC 자동 트리거"). 이 화면은 ExchangeEvent만
/// 기다린다 — MPC/UWB 세부는 GyeopKit 안에 갇힌다 (Core 계약 경계).
public struct ClipBumpView: View {
    public init() {}

    public var body: some View {
        // Dynamic Type 극단에서 제목+캡션이 화면을 넘칠 수 있어 스크롤 가능하게 한다
        // (ExchangeView.progress와 같은 패턴).
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                ProgressView()
                    .controlSize(.large)
                VStack(spacing: DS.Spacing.s) {
                    Text("아이폰을\n서로 가까이")
                        .font(DS.Typo.largeTitle)
                        .multilineTextAlignment(.center)
                    Text("가까워지는 것 자체가 동의예요. 서버 없이, 와이파이 없이.")
                        .font(DS.Typo.body)
                        .foregroundStyle(DS.Palette.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.xl)
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("아이폰을 서로 가까이. 카드를 교환하는 중")
    }
}

#Preview {
    ClipBumpView()
}
