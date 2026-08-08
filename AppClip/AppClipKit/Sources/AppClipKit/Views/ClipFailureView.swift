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
        VStack(spacing: DS.Spacing.l) {
            Spacer()
            Text(message)
                .font(DS.Typo.title)
                .multilineTextAlignment(.center)
            Button {
                Task { await onRetry() }
            } label: {
                Text("다시 시도")
                    .font(DS.Typo.headline)
                    .frame(maxWidth: .infinity, minHeight: DS.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("clip.failure.retry")
            Spacer()
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.background)
    }
}

#Preview {
    ClipFailureView(failure: .timedOut) {}
}
