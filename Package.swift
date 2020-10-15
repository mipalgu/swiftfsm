// swift-tools-version:5.0

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
    .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master"))
]

func convert(_ arr: [String]) -> [Target.Dependency] {
    return arr.map {.byName(name: $0) }
}

let foundationDeps: [Target.Dependency] = [.byName(name: "Machines"), .byName(name: "IO")]
let deps = [
    .package(url: "ssh://git.mipal.net/git/swiftfsm_FSM.git", .branch("binaries")),
    .package(url: "ssh://git.mipal.net/git/Machines.git", .branch("binaries")),
    .package(url: "ssh://git.mipal.net/git/swift_helpers.git", .branch("master"))
] + normalDependencies

let package = Package(
    name: "swiftfsm",
    platforms: [.macOS(.v10_11)],
    products: [
        .executable(
            name: "swiftfsm",
            targets: ["swiftfsm_bin"]
        ),
        .executable(
            name: "swiftfsmc",
            targets: ["swiftfsmc"]
        ),
        .library(
            name: "CFSMs",
            type: .dynamic,
            targets: ["CFSMs"]
        ),
        .library(
            name: "swiftfsm_binaries",
            targets: ["swiftfsm_binaries"]
        )
    ],
    dependencies: deps,
    targets: [
        .target(name: "CFSMs", dependencies: []),
        .target(name: "swiftfsm_helpers", dependencies: []),
        .target(name: "Gateways", dependencies: ["FSM"]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers", "FSM"]),
        .target(name: "Libraries", dependencies: ["FSM"]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers", "FSM"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers", "MachineCompiling", "FSM"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: ["FSM"] + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways", "FSM"]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways", "FSM"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification", "MachineCompiling", "FSM"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers", "FSM"]),
        .target(
            name: "swiftfsm_binaries",
            dependencies: [
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
                "FSM"
            ]
        ),
        .target(
            name: "swiftfsmc",
            dependencies: [
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
                "FSM"
            ]
        ),
        .target(
            name: "swiftfsm_bin",
            dependencies: [
                "CFSMs",
                "swiftfsm_helpers",
                "Libraries",
                "MachineStructure",
                "MachineLoading",
                "MachineCompiling",
                "Scheduling",
                "Timers",
                "Parsing",
                "Verification",
                "CFSMWrappers",
                "Gateways",
                "FSM"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsm_binariesTests", dependencies: [.target(name: "swiftfsm_binaries")]),
        .testTarget(name: "swiftfsm_binTests", dependencies: [.target(name: "swiftfsm_bin")])
    ]
)
