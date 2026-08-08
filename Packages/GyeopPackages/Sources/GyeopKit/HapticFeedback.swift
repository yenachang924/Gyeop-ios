import Core
import Foundation

#if canImport(CoreHaptics)
import CoreHaptics
#endif

// 교환 단계별 햅틱. 패턴 파라미터(강도·날카로움)는 자리표시자 값이다 —
// 실제 감각 튜닝은 D1 세션 결정 대기, 기본값으로 우선 구현한다.
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
            let chPattern = try CHHapticPattern(events: [Self.event(for: pattern)], parameters: [])
            let player = try engine.makePlayer(with: chPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            Log.nearby.error("haptic play failed: \(String(describing: error), privacy: .public)")
        }
        #endif
    }

    #if canImport(CoreHaptics)
    private static func event(for pattern: HapticPattern) -> CHHapticEvent {
        let (intensity, sharpness): (Float, Float)
        switch pattern {
        case .peerFound: (intensity, sharpness) = (0.4, 0.3)
        case .connected: (intensity, sharpness) = (0.6, 0.5)
        case .completed: (intensity, sharpness) = (1.0, 0.8)
        case .failed: (intensity, sharpness) = (0.5, 0.1)
        }
        return CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0
        )
    }
    #endif
}
