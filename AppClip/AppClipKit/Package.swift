// swift-tools-version: 6.0
import PackageDescription

// App Clip 전용 로직·뷰. Xcode `GyeopClip` 타깃(project.yml 활성화 후, S1/S6 소관)이
// 이 패키지의 AppClipKit 프로덕트에 의존해 얇은 진입점(../App)만 남긴다.
// 지금은 project.yml이 잠겨 있으므로 `swift test`로 독립적으로 빌드·검증한다.
let package = Package(
    name: "AppClipKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "AppClipKit", targets: ["AppClipKit"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GyeopPackages"),
    ],
    targets: [
        .target(
            name: "AppClipKit",
            dependencies: [
                .product(name: "Core", package: "GyeopPackages"),
                .product(name: "DesignSystem", package: "GyeopPackages"),
                .product(name: "CardKit", package: "GyeopPackages"),
            ]
        ),
        .testTarget(name: "AppClipKitTests", dependencies: ["AppClipKit"]),
    ],
    swiftLanguageModes: [.v6]
)
