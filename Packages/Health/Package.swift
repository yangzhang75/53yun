// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Health",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Health", targets: ["Health"])
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Engine")
    ],
    targets: [
        .target(
            name: "Health",
            dependencies: ["DesignSystem", "Engine"]
        ),
        .testTarget(
            name: "HealthTests",
            dependencies: ["Health"]
        )
    ]
)
