// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mixing",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Mixing", targets: ["Mixing"])
    ],
    dependencies: [
        .package(path: "../Engine"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "Mixing",
            dependencies: ["Engine", "DesignSystem"]
        ),
        .testTarget(
            name: "MixingTests",
            dependencies: ["Mixing", "Engine"]
        )
    ]
)
