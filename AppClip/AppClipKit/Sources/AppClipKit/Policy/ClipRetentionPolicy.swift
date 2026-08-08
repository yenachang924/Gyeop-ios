import Foundation

/// 풀 앱을 설치하지 않고 클립만 쓴 사용자의 데이터 보존 정책.
/// 클립은 계정이 없다 — 로컬(App Group) 저장만 하고, 설치 전환 없이는 기기에 30일만 남는다.
public enum ClipRetentionPolicy {
    public static let retentionDays = 30

    public static func expiryDate(from receivedAt: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: retentionDays, to: receivedAt) ?? receivedAt
    }

    /// 설치 제안 화면에 보여줄 안내 문구. 리터럴 폰트/색은 뷰에서 DesignSystem 토큰으로 감싼다.
    public static func noticeText(receivedAt: Date = .now, calendar: Calendar = .current) -> String {
        "이 카드는 \(retentionDays)일 뒤 이 기기에서 사라져요. 지금 겹을 설치하면 컬렉션에 계속 남아요."
    }
}
