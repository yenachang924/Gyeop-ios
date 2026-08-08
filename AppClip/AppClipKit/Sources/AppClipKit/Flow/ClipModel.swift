import Core
import Foundation
import Observation

/// 클립 조립 지점 + 상태. App의 AppModel과 같은 역할이지만 클립 전용:
/// 계정이 없고, 저장은 App Group 안의 클립 전용 스토어(지금은 인메모리 Mock)를 쓰며,
/// 실기기 MPC/UWB 배선은 GyeopKit 세션(S6)이 이 자리에 ExchangeSession 실구현을 꽂아 넣는다.
@MainActor
@Observable
public final class ClipModel {
    public private(set) var stage: ClipStage = .invocation
    public private(set) var invocation: ClipInvocation?
    public private(set) var myCard: CardSnapshot?

    private let cardGenerator: any CardGenerating
    private let repository: any GyeopRepository
    private let makeExchangeSession: @Sendable () -> any ExchangeSession
    private let onGyeopRecorded: @Sendable (GyeopRecord) -> Void

    public init(
        cardGenerator: any CardGenerating,
        repository: any GyeopRepository,
        makeExchangeSession: @escaping @Sendable () -> any ExchangeSession,
        onGyeopRecorded: @escaping @Sendable (GyeopRecord) -> Void = { _ in }
    ) {
        self.cardGenerator = cardGenerator
        self.repository = repository
        self.makeExchangeSession = makeExchangeSession
        self.onGyeopRecorded = onGyeopRecorded
    }

    /// 시뮬레이터·기본 조립: 카드 생성·저장·교환 전부 Mock, 겹 성립 시 App Group에도 남긴다
    /// (App Group 자체는 project.yml 활성화 전엔 엔타이틀먼트가 없어 조용히 no-op한다).
    /// 실배선(GyeopKit 실 ExchangeSession, DataKit App Group 스토어)은 App 조립 지점에서 S6이 교체한다.
    public static func live() -> ClipModel {
        let pendingWriter = ClipPendingGyeopWriter(appGroupID: "group.com.gyeop.app")
        return ClipModel(
            cardGenerator: MockCardGenerator(),
            repository: MockGyeopRepository(),
            makeExchangeSession: { MockExchangeSession() },
            onGyeopRecorded: { pendingWriter.append($0) }
        )
    }

    /// 인보케이션 URL 수신 — 링크 탭이든 QR 스캔이든 여기로 모인다.
    public func receive(invocationURL: URL) {
        do {
            invocation = try InvocationURLParser.parse(invocationURL)
        } catch {
            ClipLog.flow.error("인보케이션 URL 파싱 실패: \(error, privacy: .public)")
            invocation = nil
        }
        stage = .onboarding
    }

    /// 빠른 프로필 입력 완료 → 카드 생성 → 곧바로 교환 시작.
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
            myCard = card
            await startExchange(with: card)
        } catch {
            ClipLog.flow.error("클립 온보딩 저장 실패: \(error, privacy: .public)")
            stage = .failed(.transferCorrupted)
        }
    }

    public func retryExchange() async {
        guard let card = myCard else { return }
        await startExchange(with: card)
    }

    private func startExchange(with card: CardSnapshot) async {
        stage = .exchanging
        let session = makeExchangeSession()
        do {
            try await session.start(broadcasting: card)
            for await event in session.events {
                switch event {
                case .completed(let record):
                    try? await repository.record(record)
                    onGyeopRecorded(record)
                    // 교환이 끝난 뒤에만 설치를 제안한다 — 이 순서가 제품의 핵심 주장.
                    stage = .suggestingInstall(record)
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
}
