import Core
import Foundation
import Synchronization
import Testing
@testable import AppClipKit

@Suite("ClipModel 클립 레인 (navigation-map §1)")
@MainActor
struct ClipModelTests {
    private func makeModel(
        counterpart: CardSnapshot = MockData.sampleCards[0],
        makeSession: (@Sendable (CardSnapshot) -> any ExchangeSession)? = nil,
        onGyeopRecorded: @escaping @Sendable (GyeopRecord) -> Void = { _ in }
    ) -> ClipModel {
        ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: makeSession
                ?? { _ in MockExchangeSession(counterpart: counterpart, stepDelay: .zero) },
            onGyeopRecorded: onGyeopRecorded
        )
    }

    @MainActor
    private func advanceToCard(_ model: ClipModel) async {
        model.beginOnboarding()
        await model.completeOnboarding(
            nickname: "겹이",
            tagline: "달리기 좋아해요",
            emoji: "🏃",
            interests: ["클라이밍", "보드게임"],
            style: LeisureStyle(energy: .active, venue: .outdoor)
        )
    }

    @Test("수신 → 온보딩 → card → bump → overlap → keep → done 레인을 순서대로 관통한다")
    func fullLaneTraversal() async throws {
        let counterpart = MockData.sampleCards[0]
        let model = makeModel(counterpart: counterpart)

        // 1 clip: 인보케이션 수신 — reception에 머물며 초대 정보만 채운다
        model.receive(invocationURL: URL(string: "https://clip.gyeop.example/clip?t=abc123&n=지수")!)
        #expect(model.stage == .reception)
        #expect(model.invocation?.exchangeToken == "abc123")
        #expect(model.inviterNickname == "지수")

        // 「내 카드 만들기」 → 온보딩
        model.beginOnboarding()
        #expect(model.stage == .onboarding)

        // 온보딩 완주 → card (여기서 자동 교환하지 않는다 — 맞대기는 별도 진입)
        await model.completeOnboarding(
            nickname: "겹이", tagline: "달리기 좋아해요", emoji: "🏃",
            interests: ["클라이밍", "보드게임"], style: LeisureStyle(energy: .active, venue: .outdoor)
        )
        guard case .card(let card) = model.stage else {
            Issue.record("온보딩 완주 후 card 단계여야 하는데 \(model.stage)")
            return
        }
        #expect(card.nickname == "겹이")
        #expect(model.myCard == card)

        // 「맞대기」 → bump → 교환 성립 → overlap
        await model.startBump()
        guard case .overlap(let record) = model.stage else {
            Issue.record("교환 성립 후 overlap 단계여야 하는데 \(model.stage)")
            return
        }
        #expect(record.counterpartCard.ownerID == counterpart.ownerID)

        // 「카드 받기」 → keep (SKOverlay가 가능한 유일한 단계)
        model.acceptCard()
        #expect(model.stage == .keep(record))

        // 「나중에 할게요」 → done (거절 비용 0)
        model.declineInstall()
        #expect(model.stage == .done(record))
    }

    @Test("keep 이전 단계에서는 설치 제안 상태에 도달할 수 없다 — acceptCard·declineInstall은 해당 단계에서만 동작")
    func installSuggestionOnlyReachableAfterExchange() async {
        let model = makeModel()

        // reception·onboarding·card 어디서도 keep으로 건너뛸 수 없다
        model.acceptCard()
        #expect(model.stage == .reception)
        model.declineInstall()
        #expect(model.stage == .reception)

        await advanceToCard(model)
        model.acceptCard()
        guard case .card = model.stage else {
            Issue.record("card 단계에서 acceptCard는 무시돼야 하는데 \(model.stage)")
            return
        }
    }

    @Test("겹 성립 시 onGyeopRecorded 훅(마이그레이션 우편함)이 정확히 그 기록으로 호출된다")
    func firesOnGyeopRecordedHookOnCompletion() async {
        let counterpart = MockData.sampleCards[0]
        let recorded = Mutex<GyeopRecord?>(nil)
        let model = makeModel(counterpart: counterpart, onGyeopRecorded: { record in
            recorded.withLock { $0 = record }
        })

        model.receive(invocationURL: URL(string: "gyeop://clip?t=t1")!)
        await advanceToCard(model)
        await model.startBump()

        #expect(recorded.withLock { $0?.counterpartCard.ownerID } == counterpart.ownerID)
    }

    @Test("잘못된 초대 URL이어도 레인은 계속된다 (초대 정보만 비어있다)")
    func invalidInvocationStillProceeds() {
        let model = makeModel()

        model.receive(invocationURL: URL(string: "mailto:foo@example.com")!)

        #expect(model.stage == .reception)
        #expect(model.invocation == nil)

        model.beginOnboarding()
        #expect(model.stage == .onboarding)
    }

    @Test("교환 실패 시 failed 단계로 가고, 재시도하면 overlap까지 회복한다")
    func retryRecoversFromFailure() async {
        // 첫 호출은 실패, 이후는 성공 — Mutex로 감싸 @Sendable 클로저 안에서 안전하게 상태를 넘긴다.
        let attempt = Mutex(0)
        let model = makeModel(makeSession: { _ in
            let isFirstAttempt = attempt.withLock { count -> Bool in
                defer { count += 1 }
                return count == 0
            }
            return MockExchangeSession(stepDelay: .zero, failure: isFirstAttempt ? .timedOut : nil)
        })

        model.receive(invocationURL: URL(string: "gyeop://clip?t=t1")!)
        await advanceToCard(model)
        await model.startBump()
        #expect(model.stage == .failed(.timedOut))

        await model.retryExchange()
        guard case .overlap = model.stage else {
            Issue.record("재시도 후 overlap 단계여야 하는데 \(model.stage)")
            return
        }
    }
}
