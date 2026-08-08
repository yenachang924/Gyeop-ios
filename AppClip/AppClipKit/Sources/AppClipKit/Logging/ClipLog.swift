import Foundation
import OSLog

/// 클립 전용 로거. Core.Log는 다른 세션과 공유 계약이라 건드리지 않고,
/// 클립 소유 카테고리를 여기 따로 둔다 (CLAUDE.md: print 금지, OSLog만).
public enum ClipLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gyeop.app.Clip"

    /// 초대 URL 파싱, 온보딩, 교환, 설치 제안까지 클립 플로우 전체
    public static let flow = Logger(subsystem: subsystem, category: "clip.flow")
    /// 클립→풀앱 App Group 데이터 마이그레이션
    public static let migration = Logger(subsystem: subsystem, category: "clip.migration")
}
