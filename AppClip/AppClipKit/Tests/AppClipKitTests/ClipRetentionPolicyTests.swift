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
        let text = ClipRetentionPolicy.noticeText(receivedAt: .now)
        #expect(text.contains("\(ClipRetentionPolicy.retentionDays)일"))
    }
}
