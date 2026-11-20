// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PrimitivesTests",
    // platforms: [
    //     .iOS(.v13),
    //     .macOS(.v13)
    // ],
    products: [
        .executable(
            name: "t_primitives",
            targets: ["PrimitivesTests"]
        ),
        .executable(
            name: "t_p_case",
            targets: ["PrimitivesCasingTests"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Testing.git",
            branch: "master"
        ),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "PrimitivesTests",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(
                    name: "Testing",
                    package: "Testing"
                ),
            ]
        ),
        .executableTarget(
            name: "PrimitivesCasingTests",
            dependencies: [.product(name: "Primitives", package: "Primitives")]
        ),
    ]
)
