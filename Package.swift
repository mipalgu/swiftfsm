// swift-tools-version:5.0

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0"))
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
    products: [
        .executable(
            name: "swiftfsm",
            targets: ["swiftfsm_bin"]
        ),
        .executable(
            name: "swiftfsm-build",
            targets: ["swiftfsm_build"]
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
        .target(name: "Gateways", dependencies: ["FSM"]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers", "FSM"]),
        .target(name: "Libraries", dependencies: ["FSM"]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers", "FSM"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers", "MachineCompiling", "FSM"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: ["FSM"] + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways", "FSM"]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways", "FSM"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification", "MachineCompiling", "FSM"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers", "FSM", "CLReflect"]),
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
            name: "swiftfsm_build",
            dependencies: [
                "swiftfsm_binaries"
            ]
        ),
        .target(
            name: "swiftfsm_run",
            dependencies: [
                "swiftfsm_binaries"
            ]
        ),
        .target(
            name: "swiftfsm_show",
            dependencies: [
                "swiftfsm_binaries"
            ]
        ),
        .target(
            name: "swiftfsm_update",
            dependencies: [
                "swiftfsm_binaries"
            ]
        ),
        .target(
            name: "swiftfsm_verify",
            dependencies: [
                "swiftfsm_binaries"
            ]
        ),
        .target(
            name: "swiftfsm_bin",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "swiftfsm_binaries"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsm_binariesTests", dependencies: [.target(name: "swiftfsm_binaries")])
    ]
)
