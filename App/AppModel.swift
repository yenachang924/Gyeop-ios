import CardKit
import Core
import DataKit
import Foundation
import GyeopKit
import Observation

/// 앱 조립 지점 + 최상위 상태. 구현 모듈을 Core 프로토콜로만 묶는다 —
/// 여기가 에러의 최종 호출부다 (여기서만 catch, CLAUDE.md).
@MainActor
@Observable
final class AppModel {
    /// 연관값이 없어 Equatable이 자동 합성된다 — `RootView`가 `animation(value:)`로 쓴다.
    enum Stage {
        case loading
        case signIn
        case onboarding
        case home
    }

    private(set) var stage: Stage = .loading
    private(set) var myCard: CardSnapshot?
    private(set) var gyeops: [GyeopRecord] = []

    private let cardGenerator: any CardGenerating
    private let repository: any GyeopRepository
    /// 교환 세션 팩토리 — 판마다 새 세션. 실기기는 MPC, 시뮬레이터·프리뷰는 Mock.
    private let makeExchangeSession: @Sendable (CardSnapshot) -> any ExchangeSession
    /// 온보딩 전 로그인 게이트를 건너뛸지 (UI 테스트·프리뷰 전용)
    private let requiresSignIn: Bool
    /// 계정 삭제 실행 (심사 5.1.1(v)). 조립 시점에 실구현이 주입된다.
    private let deleteAccountAction: @Sendable () async throws -> Void

    private let tokenStore = KeychainTokenStore()

    init(
        cardGenerator: any CardGenerating,
        repository: any GyeopRepository,
        makeExchangeSession: @escaping @Sendable (CardSnapshot) -> any ExchangeSession = { _ in
            MockExchangeSession()
        },
        requiresSignIn: Bool = false,
        deleteAccountAction: @escaping @Sendable () async throws -> Void = {}
    ) {
        self.cardGenerator = cardGenerator
        self.repository = repository
        self.makeExchangeSession = makeExchangeSession
        self.requiresSignIn = requiresSignIn
        self.deleteAccountAction = deleteAccountAction
    }

    /// 실기기·시뮬레이터 공통 조립: 카드 생성 CardKit, 저장 SwiftData, 교환은
    /// 실기기 MPC / 시뮬레이터 Mock. SwiftData 컨테이너 생성 실패 시 인메모리
    /// Mock으로 강등 (앱은 죽지 않는다).
    static func live() -> AppModel {
        // 시뮬레이터 QA·UI 테스트용: 목업 교환을 실패 시나리오로 강제
        let mockFailure: ExchangeFailure? =
            CommandLine.arguments.contains("-mock-exchange-fail") ? .timedOut : nil

        // UI 테스트는 매번 첫 실행이어야 한다 — 인메모리 저장소 + 로그인 게이트 생략
        if CommandLine.arguments.contains("-uitest-reset") {
            return AppModel(
                cardGenerator: CardGenerator(),
                repository: MockGyeopRepository(),
                makeExchangeSession: { _ in MockExchangeSession(failure: mockFailure) }
            )
        }
        do {
            let repository = try SwiftDataGyeopRepository.live()
            let tokenStore = KeychainTokenStore()
            return AppModel(
                cardGenerator: CardGenerator(),
                repository: repository,
                makeExchangeSession: { card in
                    #if targetEnvironment(simulator)
                    // MPC는 실기기 전용 (docs/device-required.md) — 시뮬레이터는 스크립트 Mock
                    _ = card
                    return MockExchangeSession(failure: mockFailure)
                    #else
                    return MultipeerExchangeSession(displayName: exchangeDisplayName(for: card))
                    #endif
                },
                requiresSignIn: true,
                deleteAccountAction: {
                    try await AccountDeletionService(repository: repository, tokenStore: tokenStore)
                        .deleteAccount()
                }
            )
        } catch {
            Log.sync.error("SwiftData 컨테이너 생성 실패, 인메모리로 강등: \(error)")
            // 저장소가 강등돼도 로그인 게이트는 유지한다 (F44) — 기본값(false)에 기대면
            // 이 경로에서만 웰컴 화면이 통째로 사라진다.
            return AppModel(
                cardGenerator: CardGenerator(),
                repository: MockGyeopRepository(),
                requiresSignIn: true
            )
        }
    }

    /// MCPeerID 제약(UTF-8 63바이트)에 맞춘 표시 이름. 닉네임이 겹쳐도 피어가
    /// 구분되도록 ownerID 앞 8자를 붙인다.
    private nonisolated static func exchangeDisplayName(for card: CardSnapshot) -> String {
        let suffix = String(card.ownerID.suffix(8))
        return "\(String(card.nickname.prefix(12)))#\(suffix)"
    }

    func bootstrap() async {
        guard stage == .loading else { return }
        clearTokenIfFreshInstall()
        do {
            try await migratePendingClipGyeops()
            if let card = try await repository.myCard() {
                myCard = card
                try await refreshGyeops()
                stage = .home
            } else {
                stage = signedIn ? .onboarding : .signIn
            }
        } catch {
            Log.sync.error("부트스트랩 실패: \(error)")
            stage = signedIn ? .onboarding : .signIn
        }
    }

    // MARK: - 로그인 (Sign in with Apple)

    private var signedIn: Bool {
        guard requiresSignIn else { return true }
        return (try? tokenStore.loadToken()) != nil
    }

    /// **Keychain은 앱을 삭제해도 기기에 남는다** (iOS 설계). 그래서 앱을 지우고 다시 깔아도
    /// 이전 토큰이 살아 있어 로그인 게이트를 건너뛰고 바로 들어가 버렸다 (F44).
    ///
    /// UserDefaults는 앱과 함께 지워지므로, 이 플래그가 없다는 것은 곧 "재설치 후 첫 실행"이다.
    /// 그때 토큰을 비워 웰컴 화면부터 시작하게 한다 — 사용자에게도 맞는 동작이다(기기에서
    /// 앱을 지운 뒤 다시 깔면 새로 로그인하는 게 자연스럽다).
    private func clearTokenIfFreshInstall() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.installedFlagKey) else { return }
        do {
            try tokenStore.deleteToken()
        } catch {
            Log.sync.error("재설치 첫 실행 토큰 정리 실패: \(error)")
        }
        defaults.set(true, forKey: Self.installedFlagKey)
    }

    /// 재설치 감지 플래그 — 앱 삭제 시 UserDefaults와 함께 사라진다.
    private static let installedFlagKey = "gyeop.hasLaunchedSinceInstall"

    /// WelcomeView가 SIWA 성공 후 호출. 토큰은 Keychain에만 저장한다.
    func completeSignIn(identityToken: String) {
        do {
            try tokenStore.save(identityToken)
        } catch {
            // Keychain 실패는 진행을 막지 않는다 — 다음 실행에서 재로그인
            Log.sync.error("토큰 저장 실패: \(error)")
        }
        stage = .onboarding
    }

    /// 계정 삭제 — 프로필·카드·겹·토큰 전부. **화면 단계는 바꾸지 않는다** (F50).
    ///
    /// 설정 시트가 닫히는 동안 루트까지 함께 갈아치우면 전환이 거칠어져서, 단계 이동은
    /// 호출부가 시트를 닫은 뒤 `returnToEntry()`로 따로 시킨다.
    func deleteAccount() async -> Bool {
        do {
            try await deleteAccountAction()
            myCard = nil
            gyeops = []
            return true
        } catch {
            Log.sync.error("계정 삭제 실패: \(error)")
            return false
        }
    }

    /// 삭제 후 처음 화면으로 — 로그인 게이트가 켜져 있으면 웰컴, 아니면 온보딩.
    func returnToEntry() {
        stage = requiresSignIn ? .signIn : .onboarding
    }

    // MARK: - 온보딩

    /// 온보딩 완주 → 카드 생성·저장. 반환된 카드를 리빌 화면이 보여준다.
    func completeOnboarding(
        nickname: String,
        tagline: String,
        emoji: String,
        interests: [String],
        style: LeisureStyle
    ) async -> CardSnapshot? {
        let profile = UserProfile(
            id: "user-\(UUID().uuidString.lowercased())",
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

    // MARK: - 교환 (카드 맞대기)

    /// 맞대기 한 판 세션. 내 카드가 없으면 nil (교환 진입 버튼이 이미 막지만 방어).
    func startExchange() -> (any ExchangeSession)? {
        guard let myCard else { return nil }
        return makeExchangeSession(myCard)
    }

    /// 교환 성립 기록. `record`는 멱등(같은 GyeopID·24시간 동일 상대 규칙은 리포지토리 소관).
    func recordGyeop(_ record: GyeopRecord) async {
        do {
            try await repository.record(record)
            try await refreshGyeops()
        } catch {
            Log.sync.error("겹 기록 실패: \(error)")
        }
    }

    private func refreshGyeops() async throws {
        gyeops = try await repository.gyeops()
    }

    /// App Clip이 App Group에 남긴 겹을 본앱 저장소로 병합 (멱등).
    /// App Group 미설정·잔여 데이터 없음이면 0건으로 조용히 지나간다.
    private func migratePendingClipGyeops() async throws {
        let migrated = try await ClipMigrationReceiver(
            appGroupID: "group.com.gyeop.app",
            repository: repository
        ).migrate()
        if migrated > 0 {
            Log.sync.info("클립 겹 \(migrated, privacy: .public)건 병합")
        }
    }
}
