// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIUtility",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "UIUtility",
            targets: ["UIUtility"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UIUtility",
            dependencies: []),
        .testTarget(
            name: "UIUtilityTests",
            dependencies: ["UIUtility"]),
    ]
)
