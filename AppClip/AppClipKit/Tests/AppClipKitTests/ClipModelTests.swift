import Core
import Foundation
import Synchronization
import Testing
@testable import AppClipKit

@Suite("ClipModel 플로우")
@MainActor
struct ClipModelTests {
    @Test("초대 URL 수신 → 온보딩 → 교환 → 설치 제안까지 관통한다")
    func fullFlowReachesInstallSuggestion() async throws {
        let counterpart = MockData.sampleCards[0]
        let model = ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: { MockExchangeSession(counterpart: counterpart, stepDelay: .zero) }
        )

        let url = URL(string: "https://clip.gyeop.example/c?t=abc123&n=지호")!
        model.receive(invocationURL: url)
        #expect(model.stage == .onboarding)
        #expect(model.invocation?.exchangeToken == "abc123")
        #expect(model.invocation?.inviterNickname == "지호")

        await model.completeOnboarding(
            nickname: "겹이",
            tagline: "달리기 좋아해요",
            emoji: "🏃",
            interests: ["클라이밍", "보드게임"],
            style: LeisureStyle(energy: .active, venue: .outdoor)
        )

        guard case .suggestingInstall(let record) = model.stage else {
            Issue.record("교환 완료 후 설치 제안 단계로 가야 하는데 \(model.stage)에 머물러 있다")
            return
        }
        #expect(record.counterpartCard.ownerID == counterpart.ownerID)
        #expect(model.myCard?.nickname == "겹이")
    }

    @Test("겹 성립 시 onGyeopRecorded 훅이 정확히 그 기록으로 호출된다")
    func firesOnGyeopRecordedHookOnCompletion() async {
        let counterpart = MockData.sampleCards[0]
        let recorded = Mutex<GyeopRecord?>(nil)
        let model = ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: { MockExchangeSession(counterpart: counterpart, stepDelay: .zero) },
            onGyeopRecorded: { record in recorded.withLock { $0 = record } }
        )

        model.receive(invocationURL: URL(string: "gyeop://clip?t=t1")!)
        await model.completeOnboarding(
            nickname: "겹이", tagline: "", emoji: "🏃",
            interests: ["러닝"], style: LeisureStyle(energy: .active, venue: .outdoor)
        )

        #expect(recorded.withLock { $0?.counterpartCard.ownerID } == counterpart.ownerID)
    }

    @Test("잘못된 초대 URL이어도 온보딩은 계속 진행된다 (초대 정보만 비어있다)")
    func invalidInvocationStillProceedsToOnboarding() {
        let model = ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: { MockExchangeSession(stepDelay: .zero) }
        )

        model.receive(invocationURL: URL(string: "mailto:foo@example.com")!)

        #expect(model.stage == .onboarding)
        #expect(model.invocation == nil)
    }

    @Test("교환 실패 시 failed 단계로 가고, 재시도하면 완료까지 회복한다")
    func retryRecoversFromFailure() async {
        // 첫 호출은 실패, 이후는 성공 — Mutex로 감싸 @Sendable 클로저 안에서 안전하게 상태를 넘긴다.
        let attempt = Mutex(0)
        let model = ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: {
                let isFirstAttempt = attempt.withLock { count -> Bool in
                    defer { count += 1 }
                    return count == 0
                }
                return MockExchangeSession(stepDelay: .zero, failure: isFirstAttempt ? .timedOut : nil)
            }
        )

        model.receive(invocationURL: URL(string: "gyeop://clip?t=t1")!)
        await model.completeOnboarding(
            nickname: "겹이", tagline: "", emoji: "🏃",
            interests: ["러닝"], style: LeisureStyle(energy: .active, venue: .outdoor)
        )
        #expect(model.stage == .failed(.timedOut))

        await model.retryExchange()
        guard case .suggestingInstall = model.stage else {
            Issue.record("재시도 후 설치 제안 단계로 가야 하는데 \(model.stage)에 머물러 있다")
            return
        }
    }
}
