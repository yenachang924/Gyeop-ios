import Foundation
import Testing
@testable import Core

@Suite("ProfileFreshness")
struct ProfileFreshnessTests {
    @Test("29 days does not prompt for a profile refresh")
    func hidesRefreshPromptBeforeThirtyDays() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        let updatedAt = now.addingTimeInterval(-29 * 24 * 60 * 60)

        #expect(ProfileFreshness.shouldPrompt(updatedAt: updatedAt, now: now) == false)
    }

    @Test("30 days prompts for a profile refresh")
    func showsRefreshPromptAtThirtyDays() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        let updatedAt = now.addingTimeInterval(-30 * 24 * 60 * 60)

        #expect(ProfileFreshness.shouldPrompt(updatedAt: updatedAt, now: now))
    }
}
