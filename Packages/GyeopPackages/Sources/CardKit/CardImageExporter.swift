import Core
import SwiftUI

/// 카드 이미지 내보내기 — 공유 시트·컬렉션 썸네일용. `ImageRenderer`는 메인 스레드 전용이라 `@MainActor`.
@MainActor
public enum CardImageExporter {
    /// 카드 실제 종횡비(0.7:1, `CardView` 기준)로 렌더링해 PNG로 인코딩한다.
    /// - Parameters:
    ///   - width: 렌더 폭(pt). 높이는 카드 종횡비로 정해진다.
    ///   - scale: 출력 배율. 3배면 공유·썸네일에 충분한 해상도다.
    public static func renderPNGData(for card: CardSnapshot, width: CGFloat = 320, scale: CGFloat = 3) -> Data? {
        let renderer = ImageRenderer(content: CardView(card: card).frame(width: width, height: width / 0.7))
        renderer.scale = scale
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #else
        return nil
        #endif
    }
}
