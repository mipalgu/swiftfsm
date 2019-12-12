// swift-tools-version:4.0

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master"))
]

func convert(_ arr: [String]) -> [Target.Dependency] {
    return arr.map {.byName(name: $0) }
}

let foundationDeps: [Target.Dependency] = [.byName(name: "Machines")]
let deps = [
    .package(url: "ssh://git.mipal.net/git/Machines.git", .branch("master")),
] + normalDependencies

let package = Package(
    name: "swiftfsm",
    products: [
        .executable(
            name: "swiftfsm",
            targets: ["swiftfsm_bin"]
        ),
        .library(
            name: "CFSMs",
            type: .dynamic,
            targets: ["CFSMs"]
        )
    ],
    dependencies: deps,
    targets: [
        .target(name: "CFSMs", dependencies: []),
        .target(name: "swiftfsm_helpers", dependencies: []),
        .target(name: "Gateways", dependencies: []),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers"]),
        .target(name: "Libraries", dependencies: []),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "Timers"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "swiftfsm_helpers"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "Gateways"]),
        .target(name: "Verification", dependencies: ["MachineStructure", "Scheduling", "Timers", "Gateways"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification"]),
        .target(name: "CFSMWrappers", dependencies: ["Libraries", "Scheduling", "Timers"]),
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
                "Gateways"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsmTests", dependencies: [.target(name: "swiftfsm_bin")])
    ]
)
