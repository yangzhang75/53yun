// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Recipes",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 仅用于本地 `swift build` / `swift test` 烟雾测试；App 目标为 iOS 17
    ],
    products: [
        .library(name: "Recipes", targets: ["Recipes"])
    ],
    dependencies: [
        // 共享数据模型（Recipe / FlavorProfile / AromaType / Component）由 Engine 统一导出。
        .package(path: "../Engine"),
        // 设计系统：颜色 / 字体 / 组件 / 动效。
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "Recipes",
            dependencies: ["Engine", "DesignSystem"],
            resources: [
                // 官方配方数据写成结构化 JSON 资源，随包分发。
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "RecipesTests",
            dependencies: ["Recipes"]
        )
    ]
)
