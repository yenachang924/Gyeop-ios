import SwiftUI

/// 카드 질감 파라미터 — 결정 R2(design-decisions)에서 그레인 등 추가 질감은
/// "결정론적 생성의 디지털적 정확함과 결이 어긋난다"는 이유로 **제외 확정**됐다.
/// 항등 변환이 곧 최종 스펙이다. 이후 질감 실험이 부활하면(docs 갱신 선행)
/// 이 구조체에 파라미터를 채우고 `cardTexture(_:)`에서 `.layerEffect`로 연결한다.
public struct CardTextureStyle: Equatable, Sendable {
    public static let placeholder = CardTextureStyle()
}

extension View {
    /// 카드 질감 적용 지점. 결정 R2에 따라 항등 변환(no-op)이 최종이다.
    public func cardTexture(_ style: CardTextureStyle = .placeholder) -> some View {
        self
    }
}
