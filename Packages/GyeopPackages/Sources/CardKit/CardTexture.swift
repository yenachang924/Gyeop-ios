import SwiftUI

/// 카드 질감(Metal `layerEffect`) 파라미터 — 셰이더 스펙은 D1 결정 대기 중이라 자리만 잡아둔다.
/// D1이 정해지면 이 구조체에 실제 파라미터를 채우고 `cardTexture(_:)`에서 `.layerEffect`로 연결한다.
public struct CardTextureStyle: Equatable, Sendable {
    public static let placeholder = CardTextureStyle()
}

extension View {
    /// 카드 질감 적용 지점. D1 파라미터 확정 전까지는 항등 변환(no-op)이다.
    public func cardTexture(_ style: CardTextureStyle = .placeholder) -> some View {
        self
    }
}
