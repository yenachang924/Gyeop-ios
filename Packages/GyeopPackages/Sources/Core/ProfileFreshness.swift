import Foundation

public enum ProfileFreshness {
    public static let refreshInterval: TimeInterval = 30 * 24 * 60 * 60

    public static func shouldPrompt(updatedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(updatedAt) >= refreshInterval
    }
}
