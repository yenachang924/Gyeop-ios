import Core
import DesignSystem
import SwiftUI

public struct ClipFailureView: View {
    let failure: ExchangeFailure
    let onRetry: () async -> Void

    public init(failure: ExchangeFailure, onRetry: @escaping () async -> Void) {
        self.failure = failure
        self.onRetry = onRetry
    }

    private var message: String {
        switch failure {
        case .peerLost: "상대와 연결이 끊겼어요"
        case .timedOut: "상대를 찾지 못했어요"
        case .transferCorrupted: "카드 전송 중 문제가 생겼어요"
        case .cancelled: "교환이 취소됐어요"
        }
    }

    public var body: some View {
        // Dynamic Type 극단에서 메시지가 길어지면 재시도 버튼이 화면 밖으로 밀릴 수 있어
        // 내용은 스크롤, 버튼은 safeAreaInset으로 항상 화면 안에 남긴다 (ExchangeView와 같은 패턴).
        ScrollView {
            Text(message)
                .font(DS.Typo.title)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xl)
                .padding(.horizontal, DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await onRetry() }
            } label: {
                Text("다시 시도")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("clip.failure.retry")
            .padding(.horizontal, DS.Spacing.m)
        }
        .background(DS.Palette.background)
    }
}

#Preview {
    ClipFailureView(failure: .timedOut) {}
}
