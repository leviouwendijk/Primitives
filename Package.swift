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
        .package(
            url: "https://github.com/leviouwendijk/Atomos.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "Primitives",
            dependencies: [
                .product(
                    name: "Atomos",
                    package: "Atomos"
                ),
            ]
        ),
    ]
)
