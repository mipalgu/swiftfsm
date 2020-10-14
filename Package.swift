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
            name: "libswiftfsm",
            targets: ["libswiftfsm"]
        )
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
        .target(name: "libswiftfsm", dependencies: [
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
        .target(name: "CFSMs", dependencies: ["libswiftfsm", "CLReflect"]),
        .target(name: "swiftfsm_helpers", dependencies: ["libswiftfsm"]),
        .target(name: "Gateways", dependencies: ["libswiftfsm"]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers", "libswiftfsm"]),
        .target(name: "Libraries", dependencies: ["libswiftfsm"]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers", "libswiftfsm"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers", "MachineCompiling", "libswiftfsm"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: ["libswiftfsm"] + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways", "libswiftfsm"]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways", "libswiftfsm"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification", "MachineCompiling", "libswiftfsm"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers", "libswiftfsm"]),
        .target(
            name: "swiftfsm_binaries",
            dependencies: [
                "libswiftfsm",
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
                "libswiftfsm",
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
                "libswiftfsm",
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
