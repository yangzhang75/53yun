// swift-tools-version: 5.9
import PackageDescription

// MARK: - Health 包（员工⑦：BAC 微醺曲线 / 健康模块）
//
// 职责：负责任饮酒模块。基于 Widmark 公式估算血液酒精浓度（BAC），
// 绘制「BAC 随时间衰减」曲线，输出预计清醒时间、温柔适饮提示与一键叫代驾占位入口。
//
// 边界：本包不重算「纯酒精摄入量」公式心脏 —— 纯酒精克数由 Engine 的 MixResult 提供，
// 经 App 层映射为 `AlcoholIntake` 注入本包。详见 README。
let package = Package(
    name: "Health",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 仅为命令行单元测试与 SwiftUI 预览可在 macOS 上构建；产品目标为 iOS 17+
    ],
    products: [
        .library(name: "Health", targets: ["Health"])
    ],
    dependencies: [
        // 集成阶段由员工① 接入：
        //   .package(path: "../Engine"),        // 提供 MixResult（纯酒精摄入量）
        //   .package(path: "../DesignSystem"),  // 提供 颜色/字体/组件 token
        // 当前 Health 包保持自包含、可独立构建与测试。
    ],
    targets: [
        .target(
            name: "Health",
            dependencies: []
        ),
        .testTarget(
            name: "HealthTests",
            dependencies: ["Health"]
        )
    ]
)
