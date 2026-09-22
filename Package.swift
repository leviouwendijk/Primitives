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
        .executable(
            name: "primtest",
            targets: ["PrimitivesTests"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Testing.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "Primitives"
        ),
        .executableTarget(
            name: "PrimitivesTests",
            dependencies: [
                "Primitives",
                .product(
                    name: "Testing",
                    package: "Testing"
                ),
            ],
            path: "Testing/PrimitivesTests"
        ),
    ]
)
