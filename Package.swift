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
        ),
        .library(
            name: "swiftfsm",
            targets: ["swiftfsm"]
        ),
        .library(
            name: "swiftfsm",
            targets: ["swiftfsm"]
        ),
    ],
    dependencies: deps,
    targets: [
        .target(name: "Utilities", dependencies: []),
        .target(name: "Logic", dependencies: []),
        .target(name: "KripkeStructure", dependencies: ["Functional", "Utilities", "Logic"]),
        .target(name: "KripkeStructureViews", dependencies: ["Hashing", "IO", "KripkeStructure", "swift_helpers"]),
        .target(name: "ModelChecking", dependencies: ["Functional", "Hashing", "IO", "swift_helpers", "Utilities", "KripkeStructure", "KripkeStructureViews"]),
        .target(name: "FSM", dependencies: ["Functional", "Utilities", "KripkeStructure", "ModelChecking"]),
        .target(name: "ExternalVariables", dependencies: ["Functional", "Utilities", "KripkeStructure", "ModelChecking", "FSM"]),
        .target(name: "FSMVerification", dependencies: ["Functional", "Utilities", "KripkeStructure", "ModelChecking", "FSM"]),
        .target(name: "swiftfsm", dependencies: [
            "Functional",
            "Utilities",
            "KripkeStructure",
            "KripkeStructureViews",
            "ModelChecking",
            "FSM",
            "ExternalVariables",
            "FSMVerification",
            "Hashing",
            "IO",
            "Trees",
            "swift_helpers"
        ]),
        .systemLibrary(name: "CLReflect", pkgConfig: "libCLReflect"),
        .target(name: "CFSMs", dependencies: ["swiftfsm", "CLReflect"]),
        .target(name: "swiftfsm_helpers", dependencies: ["swiftfsm"]),
        .target(name: "Gateways", dependencies: ["swiftfsm"]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers", "swiftfsm"]),
        .target(name: "Libraries", dependencies: ["swiftfsm"]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers", "swiftfsm"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers", "MachineCompiling", "swiftfsm"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: ["swiftfsm"] + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways", "swiftfsm"]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways", "swiftfsm"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification", "MachineCompiling", "swiftfsm"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers", "swiftfsm"]),
        .target(
            name: "swiftfsm_binaries",
            dependencies: [
                "swiftfsm",
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
                "Gateways"
            ]
        ),
        .target(
            name: "swiftfsmc",
            dependencies: [
                "swiftfsm",
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
                "Gateways"
            ]
        ),
        .target(
            name: "swiftfsm_bin",
            dependencies: [
                "swiftfsm",
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
                "Gateways"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsm_binariesTests", dependencies: [.target(name: "swiftfsm_binaries")]),
        .testTarget(name: "swiftfsm_binTests", dependencies: [.target(name: "swiftfsm_bin")])
    ]
)
