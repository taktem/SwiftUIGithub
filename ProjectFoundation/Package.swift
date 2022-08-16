// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectFoundation",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "ProjectFoundation",
            targets: ["ProjectFoundation"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProjectFoundation",
            dependencies: []),
        .testTarget(
            name: "ProjectFoundationTests",
            dependencies: ["ProjectFoundation"]),
    ]
)
