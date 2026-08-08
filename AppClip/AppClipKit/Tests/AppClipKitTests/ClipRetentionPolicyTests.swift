import Foundation
import Testing
@testable import AppClipKit

@Suite("ClipRetentionPolicy")
struct ClipRetentionPolicyTests {
    @Test("만료일은 수신일로부터 30일 뒤다")
    func expiryIsThirtyDaysLater() {
        let calendar = Calendar(identifier: .gregorian)
        let receivedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let expiry = ClipRetentionPolicy.expiryDate(from: receivedAt, calendar: calendar)
        let days = calendar.dateComponents([.day], from: receivedAt, to: expiry).day
        #expect(days == 30)
    }

    @Test("안내 문구에 보존 일수가 포함된다")
    func noticeTextIncludesRetentionDays() {
        let text = ClipRetentionPolicy.noticeText()
        #expect(text.contains("\(ClipRetentionPolicy.retentionDays)일"))
    }

    @Test("보존 집행 기준선은 현재로부터 30일 전이다")
    func cutoffIsThirtyDaysBefore() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        let cutoff = ClipRetentionPolicy.cutoffDate(now: now, calendar: calendar)
        let days = calendar.dateComponents([.day], from: cutoff, to: now).day
        #expect(days == 30)
        // 기준선 이전에 받은 카드는 이미 만료 상태다 — expiryDate와 정합
        let received31DaysAgo = calendar.date(byAdding: .day, value: -31, to: now)!
        #expect(ClipRetentionPolicy.expiryDate(from: received31DaysAgo, calendar: calendar) < now)
    }
}
