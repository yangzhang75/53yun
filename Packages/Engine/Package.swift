// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Engine",
    // iOS 17 是 App 的最低支持版本；额外声明 macOS 以便在命令行用 `swift test` 跑单测。
    // 本包为纯 Swift 计算逻辑，禁止 import SwiftUI / UIKit。
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Engine",
            targets: ["Engine"]
        )
    ],
    targets: [
        .target(
            name: "Engine"
        ),
        .testTarget(
            name: "EngineTests",
            dependencies: ["Engine"]
        )
    ]
)
