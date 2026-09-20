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
            name: "treetest",
            targets: ["PrimitivesTest"]
        ),
        // .executable(
        //     name: "primtest",
        //     targets: ["PrimitivesTestFlows"]
        // ),
    ],
    // dependencies: [
    //     .package(
    //         url: "https://github.com/leviouwendijk/TestFlows.git",
    //         branch: "master"
    //     ),
    // ],
    targets: [
        .target(
            name: "Primitives"
        ),
        .executableTarget(
            name: "PrimitivesTest",
            dependencies: [
                "Primitives",
            ]
        ),
        // .executableTarget(
        //     name: "PrimitivesTestFlows",
        //     dependencies: [
        //         "Primitives",
        //         .product(
        //             name: "TestFlows",
        //             package: "TestFlows"
        //         ),
        //     ]
        // ),
    ]
)
