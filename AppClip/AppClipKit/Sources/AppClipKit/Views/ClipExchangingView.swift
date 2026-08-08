import DesignSystem
import SwiftUI

/// 교환 진행 중 화면. GyeopKit 실 ExchangeSession(MPC→UWB)이 붙으면 그대로 재사용된다 —
/// 이 화면은 ExchangeEvent만 보고, MPC/UWB 세부는 전혀 모른다 (Core 계약 경계).
public struct ClipExchangingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DS.Spacing.l) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            VStack(spacing: DS.Spacing.s) {
                Text("카드를 교환하는 중이에요")
                    .font(DS.Typo.title)
                Text("아이폰을 맞댄 채로 잠시만 기다려주세요")
                    .font(DS.Typo.body)
                    .foregroundStyle(DS.Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("카드를 교환하는 중")
    }
}

#Preview {
    ClipExchangingView()
}
