// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Github",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Github",
            targets: ["Github"]),
    ],
    dependencies: [
        .package(path: "../ProjectFoundation")
    ],
    targets: [
        .target(
            name: "Github",
            dependencies: [
                .product(name: "ProjectFoundation", package: "ProjectFoundation"),
            ]),
        .testTarget(
            name: "GithubTests",
            dependencies: ["Github"]),
    ]
)
