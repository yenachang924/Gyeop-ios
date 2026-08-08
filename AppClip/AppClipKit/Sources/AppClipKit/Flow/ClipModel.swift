import Core
import Foundation
import Observation

/// 클립 상태 머신. App의 AppModel과 같은 자리지만 클립 전용:
/// 계정이 없고, `docs/navigation-map.md` §1 클립 레인의 선형 플로우만 안다.
/// 실구현 조립(카드 엔진·MPC·App Group 스토어)은 클립 타깃의 `ClipModel.live()`
/// (AppClip/App/ClipAssembly.swift)가 한다 — 이 타입은 Core 계약만 본다.
@MainActor
@Observable
public final class ClipModel {
    public private(set) var stage: ClipStage = .reception
    public private(set) var invocation: ClipInvocation?
    public private(set) var myCard: CardSnapshot?

    private let cardGenerator: any CardGenerating
    private let repository: any GyeopRepository
    private let makeExchangeSession: @Sendable (CardSnapshot) -> any ExchangeSession
    private let onGyeopRecorded: @Sendable (GyeopRecord) -> Void

    public init(
        cardGenerator: any CardGenerating,
        repository: any GyeopRepository,
        makeExchangeSession: @escaping @Sendable (CardSnapshot) -> any ExchangeSession,
        onGyeopRecorded: @escaping @Sendable (GyeopRecord) -> Void = { _ in }
    ) {
        self.cardGenerator = cardGenerator
        self.repository = repository
        self.makeExchangeSession = makeExchangeSession
        self.onGyeopRecorded = onGyeopRecorded
    }

    public var inviterNickname: String? { invocation?.inviterNickname }

    /// 인보케이션 URL 수신 — 링크 탭이든 QR 스캔이든 여기로 모인다.
    /// 파싱 실패는 레인을 막지 않는다 — 초대 정보만 비어 있는 채로 `reception`에 머문다.
    public func receive(invocationURL: URL) {
        do {
            invocation = try InvocationURLParser.parse(invocationURL)
        } catch {
            ClipLog.flow.error("인보케이션 URL 파싱 실패: \(error, privacy: .public)")
            invocation = nil
        }
    }

    /// `clip` 「내 카드 만들기」 → 온보딩 3단계 진입
    public func beginOnboarding() {
        guard case .reception = stage else { return }
        stage = .onboarding
    }

    /// `interests` 뒤로 스와이프 → `clip` (navigation-map §1-2, 시스템 제스처).
    /// 온보딩 단계에서만 — 카드가 만들어진 뒤에는 되돌아가지 않는다.
    public func backToReception() {
        guard case .onboarding = stage else { return }
        stage = .reception
    }

    /// 온보딩 완주 → 카드 생성 → `card`. 클립 저장 실패는 레인을 막지 않는다 —
    /// 클립의 핵심 동작(교환)은 메모리의 카드만으로 성립하고, 영속·마이그레이션은 부가다.
    public func completeOnboarding(
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        style: LeisureStyle
    ) async {
        let profile = UserProfile(
            id: "clip-user-\(UUID().uuidString.lowercased())",
            nickname: nickname,
            tagline: tagline,
            emoji: emoji,
            interests: Array(interests.prefix(UserProfile.maxInterests)),
            leisureStyle: style,
            createdAt: .now
        )
        let card = cardGenerator.makeCard(from: profile)
        do {
            try await repository.saveMyProfile(profile)
            try await repository.saveMyCard(card)
        } catch {
            ClipLog.flow.error("클립 온보딩 저장 실패(레인은 계속): \(error, privacy: .public)")
        }
        myCard = card
        stage = .card(card)
    }

    /// `card` 「맞대기」 → `bump`. 교환 성립 시 기록·마이그레이션 우편함 적재 후 `overlap`.
    public func startBump() async {
        guard let myCard else { return }
        stage = .bump
        let session = makeExchangeSession(myCard)
        do {
            try await session.start(broadcasting: myCard)
            for await event in session.events {
                switch event {
                case .completed(let record):
                    do {
                        try await repository.record(record)
                    } catch {
                        ClipLog.flow.error("클립 겹 기록 저장 실패(레인은 계속): \(error, privacy: .public)")
                    }
                    onGyeopRecorded(record)
                    stage = .overlap(record)
                case .failed(let failure):
                    stage = .failed(failure)
                case .searching, .peerFound, .connecting, .cardReceived:
                    break
                }
            }
        } catch {
            ClipLog.flow.error("교환 시작 실패: \(error, privacy: .public)")
            stage = .failed(.transferCorrupted)
        }
    }

    /// `overlap` 「카드 받기」 → `keep`
    public func acceptCard() {
        guard case .overlap(let record) = stage else { return }
        stage = .keep(record)
    }

    /// `keep` 「나중에 할게요」 → `done` (거절 비용 0 — SKOverlay 없이 컬렉션으로)
    public func declineInstall() {
        guard case .keep(let record) = stage else { return }
        stage = .done(record)
    }

    /// `keep` 「전체 앱 받기」 → SKOverlay → 완료(닫힘) 시 `done` (navigation-map §1-8)
    public func finishInstallSuggestion() {
        guard case .keep(let record) = stage else { return }
        stage = .done(record)
    }

    /// 실패 화면 「다시 시도」 → bump 재진입
    public func retryExchange() async {
        await startBump()
    }
}
