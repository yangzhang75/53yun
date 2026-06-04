// swift-tools-version: 5.9
import PackageDescription

// 「我的酒柜 / 会员」本地 Swift Package（员工⑧）
//
// 架构分层（关键）：
//  • CellarCore —— 纯 Swift 业务逻辑：微醺积分引擎、等级阈值、Recipe ↔ 持久化快照映射。
//      不依赖 SwiftData / SwiftUI 宏，因此可在纯命令行环境下 `swift test`。
//  • Cellar     —— 在 CellarCore 之上叠加 SwiftData 数据模型 + SwiftUI 视图（含 Preview）。
//      需要完整 Xcode（SwiftData / SwiftUI 宏插件）才能编译。
//
// 边界：本包只拥有「我的酒柜」相关的 SwiftData schema，与 Engine 的 Recipe 做映射，
//      不修改 Engine 模型本身。集成时由员工① 用真正的 `import Engine` / `import DesignSystem`
//      替换本包内的临时占位（见 *_Standin.swift）。
let package = Package(
    name: "Cellar",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Cellar", targets: ["Cellar"]),
        .library(name: "CellarCore", targets: ["CellarCore"]),
    ],
    dependencies: [
        // 集成接入 DesignSystem：提供 YunModule / YunTab 入口契约。
        .package(path: "../DesignSystem")
    ],
    targets: [
        // 纯逻辑层：无 SwiftData / SwiftUI 依赖
        .target(name: "CellarCore"),
        // UI + 持久化层：SwiftData @Model + SwiftUI View + Preview
        .target(name: "Cellar", dependencies: ["CellarCore", "DesignSystem"]),
        // 纯逻辑测试：本环境可直接运行
        .testTarget(name: "CellarCoreTests", dependencies: ["CellarCore"]),
        // 持久化 / 映射集成测试：需要 Xcode（SwiftData 宏）
        .testTarget(name: "CellarTests", dependencies: ["Cellar", "CellarCore"]),
    ]
)
