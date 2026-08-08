// swift-tools-version: 6.0
import PackageDescription

// 모듈 경계 = 세션 소유권 경계 (CLAUDE.md 소유권 규칙 참조)
// Core         — 계약(프로토콜·모델)·Telemetry. 모든 모듈의 유일한 공유 접점.
// DesignSystem — 색·폰트·간격 토큰. 뷰 리터럴 금지의 근거지.
// CardKit      — 정체성 카드 생성·렌더 (커스텀 비주얼이 허용된 유일한 곳).
// GyeopKit     — MPC·UWB 카드 맞대기 (실기기 전용, 시뮬레이터는 Core의 Mock).
// DataKit      — SwiftData 저장·(이후) 서버 동기화.

let package = Package(
    name: "GyeopPackages",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "CardKit", targets: ["CardKit"]),
        .library(name: "GyeopKit", targets: ["GyeopKit"]),
        .library(name: "DataKit", targets: ["DataKit"]),
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "DesignSystem"),
        .target(name: "CardKit", dependencies: ["Core", "DesignSystem"]),
        .target(name: "GyeopKit", dependencies: ["Core"]),
        .target(name: "DataKit", dependencies: ["Core"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "CardKitTests", dependencies: ["CardKit"]),
        .testTarget(name: "DataKitTests", dependencies: ["DataKit"]),
    ],
    swiftLanguageModes: [.v6]
)
