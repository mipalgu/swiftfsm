// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swiftfsm",
    products: [
        .executable(
            name: "swiftfsm",
            targets: ["swiftfsm"]
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
        .target(name: "Libraries", dependencies: ["IO"]),
        .target(name: "MachineStructure", dependencies: ["Libraries", "GUSimpleWhiteboard", "SwiftMachines"]),
        .target(name: "MachineLoading", dependencies: ["GUSimpleWhiteboard", "SwiftMachines"]),
        .target(name: "MachineCompiling", dependencies: ["SwiftMachines"]),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "GUSimpleWhiteboard"]),
        .target(name: "Parsing", dependencies: ["Scheduling"]),
        .target(name: "Verification", dependencies: ["IO", "MachineStructure", "Scheduling"]),
        .target(name: "CFSMWrappers", dependencies: ["GUSimpleWhiteboard", "Libraries", "Scheduling"]),
        .target(
            name: "swiftfsm",
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
                "Parsing",
                "Verification",
                "CFSMWrappers"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsmTests", dependencies: [.target(name: "swiftfsm")])
    ]
)
