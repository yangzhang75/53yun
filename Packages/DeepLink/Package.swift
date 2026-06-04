// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepLink",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 仅为在开发机 / CI 上跑 `swift test`（CoreImage/SwiftUI 跨平台）。
    ],
    products: [
        .library(name: "DeepLink", targets: ["DeepLink"])
    ],
    dependencies: [
        // 共享数据契约（Recipe 等）来自 Engine（员工②）。
        .package(path: "../Engine")
    ],
    targets: [
        .target(
            name: "DeepLink",
            dependencies: [
                .product(name: "Engine", package: "Engine")
            ]
        ),
        .testTarget(
            name: "DeepLinkTests",
            dependencies: ["DeepLink"]
        )
    ]
)
