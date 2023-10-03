// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FSM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "swiftfsm",
            targets: ["FSM", "InMemoryVariables", "Model", "LLFSMs"]),
        .library(
            name: "FSMTest",
            targets: ["FSMTest"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/mipalgu/KripkeStructures", from: "1.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FSM",
            dependencies: []),
        .target(
            name: "InMemoryVariables",
            dependencies: ["FSM"]),
        .target(
            name: "Model",
            dependencies: ["FSM", "InMemoryVariables"]),
        .target(
            name: "LLFSMs",
            dependencies: ["FSM", "Model"]),
        .target(
            name: "FSMTest",
            dependencies: ["FSM", "Model", "Verification"]
        ),
        .target(
            name: "Verification",
            dependencies: [
                "FSM",
                .product(name: "KripkeStructures", package: "KripkeStructures"),
                .product(name: "KripkeStructureViews", package: "KripkeStructures")
            ]
        ),
        .testTarget(
            name: "Mocks",
            dependencies: ["FSM", "Model", "LLFSMs"]),
        .testTarget(
            name: "FSMTests",
            dependencies: ["FSM", "Mocks"]),
        .testTarget(
            name: "ModelTests",
            dependencies: ["FSM", "InMemoryVariables", "Model", "Mocks"]),
        // .testTarget(
        //     name: "LLFSMsTests",
        //     dependencies: ["FSM", "Model", "LLFSMs", "Mocks"]),
        .testTarget(
            name: "InMemoryVariableTests",
            dependencies: ["InMemoryVariables"]),
        .testTarget(
            name: "VerificationTests",
            dependencies: [
                "FSM",
                "FSMTest",
                "LLFSMs",
                "Model",
                "Mocks",
                "Verification",
                .product(name: "KripkeStructures", package: "KripkeStructures"
            )])
    ]
)
