// swift-tools-version:4.0

import PackageDescription

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
    dependencies: [
        .package(url: "ssh://git.mipal.net/git/swift_wb.git", .branch("swift-4.2")),
        .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master")),
        .package(url: "ssh://git.mipal.net/git/Machines.git", .branch("master")),
        .package(url: "ssh://git.mipal.net/git/swift_helpers.git", .branch("master"))
    ],
    targets: [
        .target(name: "CFSMs", dependencies: []),
        .target(name: "swiftfsm_helpers", dependencies: []),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers"]),
        .target(name: "Libraries", dependencies: ["IO"]),
        .target(name: "MachineStructure", dependencies: ["Libraries", "GUSimpleWhiteboard", "SwiftMachines"]),
        .target(name: "MachineLoading", dependencies: ["GUSimpleWhiteboard", "SwiftMachines"]),
        .target(name: "MachineCompiling", dependencies: ["SwiftMachines"]),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "GUSimpleWhiteboard"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers"]),
        .target(name: "Verification", dependencies: ["IO", "MachineStructure", "Scheduling", "Timers"]),
        .target(name: "CFSMWrappers", dependencies: ["GUSimpleWhiteboard", "Libraries", "Scheduling", "Timers"]),
        .target(
            name: "swiftfsm_bin",
            dependencies: [
                "GUSimpleWhiteboard",
                "IO",
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
                "CFSMWrappers"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsmTests", dependencies: [.target(name: "swiftfsm_bin")])
    ]
)
