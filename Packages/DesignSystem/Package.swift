// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 仅用于本地 `swift build` 烟雾测试
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        // 字体文件就位后，把下面 resources 解注释并把 .otf 放进 Resources/Fonts：
        // resources: [.process("Resources/Fonts")]
        .target(name: "DesignSystem"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"])
    ]
)
