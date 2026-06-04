// swift-tools-version: 5.9
import PackageDescription

// AICompanion —「AI 调酒师」 (员工⑩)
//
// 依赖关系（集成时由员工① 接入）：
//   - Engine        ：共享数据契约 (Recipe / Component / AromaType / FlavorProfile / MixResult) + 度数计算
//   - DesignSystem  ：颜色 / 字体 / 组件
//
// 本包为「叶子包」，可独立编译 / 测试：
//   - 当工程中存在 Engine 包时，`#if canImport(Engine)` 会自动 `@_exported import Engine`，
//     契约类型直接复用 Engine 的定义，零改动集成；
//   - 当 Engine 不在场（独立开发 / 单测）时，使用 Sources/AICompanionCore/EngineContract 中的同名兜底契约。
//
// 集成步骤见 README.md。
let package = Package(
    name: "AICompanion",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 仅用于在 CI / 命令行跑核心逻辑单测，App 本体只面向 iOS 17+
    ],
    products: [
        .library(name: "AICompanion", targets: ["AICompanion"]),
        .library(name: "AICompanionCore", targets: ["AICompanionCore"])
    ],
    dependencies: [
        // 集成时取消注释，并删除 EngineContract 兜底契约：
        // .package(path: "../Engine"),
        // .package(path: "../DesignSystem"),
    ],
    targets: [
        // 纯逻辑层：无 SwiftUI 依赖，全部可单测。
        .target(
            name: "AICompanionCore",
            dependencies: [
                // .product(name: "Engine", package: "Engine"),
            ]
        ),
        // UI 层：SwiftUI 对话界面 + ViewModel。
        .target(
            name: "AICompanion",
            dependencies: [
                "AICompanionCore",
                // .product(name: "DesignSystem", package: "DesignSystem"),
            ]
        ),
        .testTarget(
            name: "AICompanionCoreTests",
            dependencies: ["AICompanionCore"]
        )
    ]
)
