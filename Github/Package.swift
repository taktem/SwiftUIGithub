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
        .package(path: "../ProjectFoundation"),
        .package(path: "../APIClient"),
        .package(path: "../UIUtility")
    ],
    targets: [
        .target(
            name: "Github",
            dependencies: [
                .product(name: "ProjectFoundation", package: "ProjectFoundation"),
                .product(name: "UIUtility", package: "UIUtility"),
                "Domain",
                "Infra",
            ]),
        .target(
            name: "Infra",
            dependencies: [
                .product(name: "APIClient", package: "APIClient"),
                "Domain"
            ]
        ),
        .target(
            name: "Domain",
            dependencies: []
        ),
        .testTarget(
            name: "GithubTests",
            dependencies: ["Github"]),
    ]
)
