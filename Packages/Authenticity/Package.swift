// swift-tools-version: 5.9
import PackageDescription

// MARK: - Authenticity（防伪溯源 / 扫码验真）
// 员工⑨ 负责的本地 Swift Package。
// 独立流程：只暴露 public 接口与 SwiftUI View，不直接依赖计算模块（Engine/Mixing 等）。
//
// 平台说明：
// - 业务目标平台为 iOS 17+（相机扫描使用 AVFoundation，仅在 iOS 生效）。
// - 同时声明 macOS 以便在命令行 `swift build` / `swift test` 下做无 Xcode 的逻辑验证；
//   相机相关代码以 `#if os(iOS)` 隔离，不影响其它平台编译。
let package = Package(
    name: "Authenticity",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Authenticity",
            targets: ["Authenticity"]
        )
    ],
    dependencies: [
        // 集成时由员工① 在主工程接入 DesignSystem。
        // 本包内置最小暗金主题（AuthTheme）作为兜底，集成后可平滑切换。
    ],
    targets: [
        .target(
            name: "Authenticity"
        ),
        .testTarget(
            name: "AuthenticityTests",
            dependencies: ["Authenticity"]
        )
    ]
)
