import Core
import Foundation

#if canImport(CoreHaptics)
import CoreHaptics
#endif

// 교환 단계별 햅틱. 패턴 파라미터(강도·날카로움·간격)는 전부 `HapticTuning` 상수로
// 모아뒀다 — 실기기에서 값만 바꿔 재빌드하며 감각을 튜닝한다 (U2 기본값).
//
// CoreHaptics는 실기기 전용(Simulator에서는 supportsHaptics == false)이라
// 여기서는 안전하게 no-op된다. macOS(swift test 타깃)에는 프레임워크 자체가
// 없어 canImport로 통째로 컴파일에서 뺀다 — docs/device-required.md 등록 항목.

/// 교환 단계별 햅틱 패턴.
enum HapticPattern: Sendable {
    case peerFound
    case connected
    case completed
    case failed
}

/// 실기기 감각 튜닝 상수 — 값 조정은 여기서만 한다.
/// 패턴 구조(이벤트 수·순서)는 `HapticFeedback.events(for:)`에 있다.
enum HapticTuning {
    // 실기기 1차 튜닝 (2026-08-09, 소유자 체감: "약해") — 전 단계 강도를 올렸다.
    // "겹!" 2타는 이미 최대치(1.0)라 숫자로는 못 키운다. transient는 순간 임펄스라
    // 크기의 상한이 있어, 2타 밑에 짧은 연속 진동(swell)을 깔아 몸집을 키웠다.
    // 근거는 docs/design-decisions.md §햅틱 튜닝 기록.

    static let peerFoundIntensity: Float = 0.65
    static let peerFoundSharpness: Float = 0.4
    static let connectedIntensity: Float = 0.85
    static let connectedSharpness: Float = 0.55
    /// "겹!" 더블탭 1타 — 두 카드가 살짝 닿는 예비 탭.
    static let completedFirstIntensity: Float = 1.0
    static let completedFirstSharpness: Float = 0.5
    /// "겹!" 더블탭 2타 — 도장이 찍히는 본 탭.
    static let completedSecondIntensity: Float = 1.0
    static let completedSecondSharpness: Float = 0.8
    /// 더블탭 1타 → 2타 간격 (초).
    static let completedTapGap: TimeInterval = 0.12
    /// "겹!" 2타 아래에 깔리는 연속 진동 — 임펄스만으로는 안 나오는 무게를 만든다.
    static let completedSwellIntensity: Float = 0.7
    static let completedSwellSharpness: Float = 0.25
    static let completedSwellDuration: TimeInterval = 0.22
    static let failedIntensity: Float = 0.7
    static let failedSharpness: Float = 0.15
}

/// CoreHaptics 엔진 래퍼. 실기기가 아니거나 엔진 준비 실패 시 조용히 무시한다 —
/// 햅틱은 부가 경험이지 교환 성공의 필요조건이 아니다.
actor HapticFeedback {
    #if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    #endif

    init() {}

    func prepare() {
        #if canImport(CoreHaptics)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            self.engine = engine
        } catch {
            Log.nearby.error("haptic engine start failed: \(String(describing: error), privacy: .public)")
        }
        #endif
    }

    func play(_ pattern: HapticPattern) {
        #if canImport(CoreHaptics)
        guard let engine else { return }
        do {
            let chPattern = try CHHapticPattern(events: Self.events(for: pattern), parameters: [])
            let player = try engine.makePlayer(with: chPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            Log.nearby.error("haptic play failed: \(String(describing: error), privacy: .public)")
        }
        #endif
    }

    #if canImport(CoreHaptics)
    private static func events(for pattern: HapticPattern) -> [CHHapticEvent] {
        switch pattern {
        case .peerFound:
            [transient(HapticTuning.peerFoundIntensity, HapticTuning.peerFoundSharpness)]
        case .connected:
            [transient(HapticTuning.connectedIntensity, HapticTuning.connectedSharpness)]
        case .completed:
            // "겹!" 더블탭 — 두 카드가 맞닿는 순간의 브랜드 촉각 (가볍게 → 도장).
            // 2타 시점부터 짧은 연속 진동이 깔려 임펄스에 무게를 더한다 (실기기 튜닝).
            [
                transient(HapticTuning.completedFirstIntensity, HapticTuning.completedFirstSharpness),
                transient(
                    HapticTuning.completedSecondIntensity,
                    HapticTuning.completedSecondSharpness,
                    at: HapticTuning.completedTapGap
                ),
                continuous(
                    HapticTuning.completedSwellIntensity,
                    HapticTuning.completedSwellSharpness,
                    at: HapticTuning.completedTapGap,
                    duration: HapticTuning.completedSwellDuration
                ),
            ]
        case .failed:
            [transient(HapticTuning.failedIntensity, HapticTuning.failedSharpness)]
        }
    }

    private static func transient(
        _ intensity: Float, _ sharpness: Float, at time: TimeInterval = 0
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    /// 지속 진동 — transient의 순간 임펄스로는 만들 수 없는 "무게"를 깐다.
    private static func continuous(
        _ intensity: Float, _ sharpness: Float, at time: TimeInterval, duration: TimeInterval
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time,
            duration: duration
        )
    }
    #endif
}
