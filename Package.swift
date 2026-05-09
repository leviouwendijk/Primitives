// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Primitives",
    // platforms: [
    //     .iOS(.v13),
    //     .macOS(.v13)
    // ],
    products: [
        .library(
            name: "Primitives",
            targets: ["Primitives"]
        ),
    ],
    targets: [
        .target(
            name: "Primitives"
        ),
    ]
)
