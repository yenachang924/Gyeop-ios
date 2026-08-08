import Core
import DataKit
import Foundation
import Observation

/// 앱 조립 지점 + 최상위 상태. 구현 모듈을 Core 프로토콜로만 묶는다 —
/// 여기가 에러의 최종 호출부다 (여기서만 catch, CLAUDE.md).
@MainActor
@Observable
final class AppModel {
    enum Stage {
        case loading
        case onboarding
        case home
    }

    private(set) var stage: Stage = .loading
    private(set) var myCard: CardSnapshot?
    private(set) var gyeops: [GyeopRecord] = []

    let season = MockData.season

    private let cardGenerator: any CardGenerating
    private let repository: any GyeopRepository

    init(cardGenerator: any CardGenerating, repository: any GyeopRepository) {
        self.cardGenerator = cardGenerator
        self.repository = repository
    }

    /// 실기기·시뮬레이터 공통 조립: 카드 생성은 아직 Mock, 저장은 SwiftData.
    /// SwiftData 컨테이너 생성 실패 시 인메모리 Mock으로 강등 (앱은 죽지 않는다).
    static func live() -> AppModel {
        // UI 테스트는 매번 첫 실행이어야 한다 — 인메모리 저장소로 조립
        if CommandLine.arguments.contains("-uitest-reset") {
            return AppModel(
                cardGenerator: MockCardGenerator(),
                repository: MockGyeopRepository()
            )
        }
        do {
            return AppModel(
                cardGenerator: MockCardGenerator(),
                repository: try SwiftDataGyeopRepository.live()
            )
        } catch {
            Log.sync.error("SwiftData 컨테이너 생성 실패, 인메모리로 강등: \(error)")
            return AppModel(
                cardGenerator: MockCardGenerator(),
                repository: MockGyeopRepository()
            )
        }
    }

    func bootstrap() async {
        guard stage == .loading else { return }
        do {
            if let card = try await repository.myCard() {
                myCard = card
                try await refreshGyeops()
                stage = .home
            } else {
                stage = .onboarding
            }
        } catch {
            Log.sync.error("부트스트랩 실패: \(error)")
            stage = .onboarding
        }
    }

    /// 온보딩 완주 → 카드 생성·저장. 반환된 카드를 리빌 화면이 보여준다.
    func completeOnboarding(
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        style: LeisureStyle
    ) async -> CardSnapshot? {
        let profile = RunnerProfile(
            id: "runner-\(UUID().uuidString.lowercased())",
            nickname: nickname,
            tagline: tagline,
            emoji: emoji,
            interests: Array(interests.prefix(RunnerProfile.maxInterests)),
            leisureStyle: style,
            createdAt: .now
        )
        let card = cardGenerator.makeCard(from: profile)
        do {
            try await repository.saveMyProfile(profile)
            try await repository.saveMyCard(card)
            try await seedDemoGyeopsIfEmpty()
            myCard = card
            return card
        } catch {
            Log.sync.error("온보딩 저장 실패: \(error)")
            return nil
        }
    }

    func enterCollection() async {
        do {
            try await refreshGyeops()
        } catch {
            Log.sync.error("겹 로드 실패: \(error)")
        }
        stage = .home
    }

    private func refreshGyeops() async throws {
        gyeops = try await repository.gyeops()
    }

    /// 데모용 목업 겹 — 맞대기(GyeopKit)가 붙기 전까지 컬렉션을 채운다.
    /// GyeopKit 연결 시 이 시딩을 제거할 것.
    private func seedDemoGyeopsIfEmpty() async throws {
        guard try await repository.gyeops().isEmpty else { return }
        for gyeop in MockData.sampleGyeops {
            try await repository.record(gyeop)
        }
    }
}
