// swift-tools-version:5.2

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0"))
]

func convert(_ arr: [String]) -> [Target.Dependency] {
    return arr.map {.byName(name: $0) }
}

let foundationDeps: [Target.Dependency] = [.byName(name: "Machines"), .product(name: "IO", package: "swift_helpers")]
let deps = [
    .package(name: "FSM", url: "git@github.com:mipalgu/FSM", .branch("verification")),
    .package(name: "Machines", url: "https://github.com/mipalgu/Machines", .branch("verification")),
    .package(name: "swift_helpers", url: "https://github.com/mipalgu/swift_helpers", .branch("main")),
    .package(name: "SQLite.swift", url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.3")
] + normalDependencies

let package = Package(
    name: "swiftfsm",
    products: [
        .executable(
            name: "swiftfsm_binary",
            targets: ["swiftfsm_bin"]
        ),
        .executable(
            name: "swiftfsm-add",
            targets: ["swiftfsm_add"]
        ),
        .executable(
            name: "swiftfsm-build",
            targets: ["swiftfsm_build"]
        ),
        .executable(
            name: "swiftfsm-clean",
            targets: ["swiftfsm_clean"]
        ),
        .executable(
            name: "swiftfsm-init",
            targets: ["swiftfsm_init"]
        ),
        .executable(
            name: "swiftfsm-remove",
            targets: ["swiftfsm_remove"]
        ),
        .executable(
            name: "swiftfsm-run",
            targets: ["swiftfsm_run"]
        ),
        .executable(
            name: "swiftfsm-show",
            targets: ["swiftfsm_show"]
        ),
        .executable(
            name: "swiftfsm-update",
            targets: ["swiftfsm_update"]
        ),
        .executable(
            name: "swiftfsm-verify",
            targets: ["swiftfsm_verify"]
        ),
        .library(
            name: "Verification",
            targets: ["Verification"]
        ),
        .library(
            name: "CFSMs",
            type: .dynamic,
            targets: ["CFSMs", "CLReflect"]
        ),
        .library(
            name: "swiftfsm_binaries",
            targets: ["swiftfsm_binaries"]
        )
    ],
    dependencies: deps,
    targets: [
        .target(name: "CLReflect", dependencies: []),
        .target(name: "CFSMs", dependencies: ["CLReflect"]),
        .target(name: "swiftfsm_helpers", dependencies: []),
        .target(name: "Gateways", dependencies: ["FSM", .product(name: "IO", package: "swift_helpers")]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers", "FSM"]),
        .target(name: "Libraries", dependencies: ["FSM", .product(name: "IO", package: "swift_helpers")]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers", "FSM"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers", "MachineCompiling", "FSM"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: ["FSM"] + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways", "FSM"]),
        .target(name: "KripkeStructure", dependencies: ["swift_helpers", "FSM"]),
        .target(name: "KripkeStructureViews", dependencies: ["KripkeStructure", "FSM", .product(name: "IO", package: "swift_helpers")]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways", "FSM", "KripkeStructure", "KripkeStructureViews", .product(name: "Hashing", package: "swift_helpers"), .product(name: "SQLite", package: "SQLite.swift")]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification", "MachineCompiling", "FSM"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers", "FSM", "CLReflect"]),
        .target(
            name: "swiftfsm_binaries",
            dependencies: [
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CFSMs",
                "swiftfsm_helpers",
                "Libraries",
                "MachineStructure",
                "MachineLoading",
                "MachineCompiling",
                "Scheduling",
                "Timers",
                "Verification",
                "CFSMWrappers",
                "Gateways",
                "FSM",
                "Machines"
            ]
        ),
        .target(
            name: "swiftfsm_add",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_build",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_clean",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_init",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_remove",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_run",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_show",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_update",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_verify",
            dependencies: [
                "swiftfsm_binaries",
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "swiftfsm_bin",
            dependencies: [
                .product(name: "FSM", package: "FSM"),
                .product(name: "IO", package: "swift_helpers"),
                .product(name: "Hashing", package: "swift_helpers"),
                .product(name: "Machines", package: "Machines"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "swiftfsm_binaries"
            ]
        ),
        .target(name: "CTests", dependencies: []),
        .testTarget(name: "KripkeStructureTests", dependencies: ["FSM", .target(name: "KripkeStructure")]),
        .testTarget(
            name: "VerificationTests",
            dependencies: [
                .target(name: "KripkeStructure"),
                .target(name: "KripkeStructureViews"),
                .target(name: "Verification"),
                .target(name: "CTests"),
                .target(name: "swiftfsm_binaries"),
                .product(name: "swift_helpers", package: "swift_helpers")
            ],
            exclude: ["machines"]
        ),
        .testTarget(
            name: "swiftfsm_binariesTests",
            dependencies: [
                .target(name: "swiftfsm_binaries")
            ])
    ]
)
