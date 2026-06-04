// swift-tools-version: 5.9
import PackageDescription

// 品鉴卡导出 + 分享（owner: 员工⑤）。
// 依赖 Engine（共享数据契约）与 DesignSystem（品牌色/字体）。
// 边界：本包只负责「渲染卡片 / 导出 PNG / 系统分享 / 深链字符串生成」。
// 二维码图像由员工⑥(DeepLink) 填充 —— 本包仅预留二维码视图槽位与 URL 字符串。
let package = Package(
    name: "ShareCard",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ShareCard", targets: ["ShareCard"])
    ],
    dependencies: [
        .package(path: "../Engine"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "ShareCard",
            dependencies: ["Engine", "DesignSystem"]
        ),
        .testTarget(
            name: "ShareCardTests",
            dependencies: ["ShareCard", "Engine"]
        )
    ]
)
