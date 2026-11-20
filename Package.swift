// swift-tools-version: 6.2

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
    dependencies: [
    ],
    targets: [
        .target(
            name: "Primitives"
        ),
    ]
)
