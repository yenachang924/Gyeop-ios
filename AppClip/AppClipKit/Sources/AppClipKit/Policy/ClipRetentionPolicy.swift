import Foundation

/// 풀 앱을 설치하지 않고 클립만 쓴 사용자의 데이터 보존 정책.
/// 클립은 계정이 없다 — App Group 로컬 저장만 하고, 설치 전환 없이는 기기에 30일만 남는다.
/// 집행(만료 겹 삭제)은 클립 조립 지점이 실행 시마다 `cutoffDate()` 이전 기록을 지우는 것으로 한다.
public enum ClipRetentionPolicy {
    public static let retentionDays = 30

    public static func expiryDate(from receivedAt: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: retentionDays, to: receivedAt) ?? receivedAt
    }

    /// 보존 집행 기준선 — 이 시각보다 오래된 겹 기록은 클립 스토어에서 삭제한다.
    public static func cutoffDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -retentionDays, to: now) ?? now
    }

    /// `keep` 화면 안내 문구 (카피: gyeop-prototype.html keep-note). 폰트/색은 뷰에서 DS 토큰으로.
    public static func noticeText() -> String {
        "App Clip에서 받은 카드는 \(retentionDays)일 뒤 사라져요. 전체 앱에서는 겹이 계속 쌓입니다."
    }
}
