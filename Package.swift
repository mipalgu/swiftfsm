// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swiftfsm",
    products: [
        .executable(
            name: "swiftfsm",
            targets: ["swiftfsm"]
        )
    ],
    dependencies: [
        .package(url: "ssh://git.mipal.net/git/swift_wb.git", .branch("master")),
        .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master"))
    ],
    targets: [
        .target(name: "IO", dependencies: []),
        .target(name: "CFSMs", dependencies: []),
        .target(name: "swiftfsm_helpers", dependencies: []),
        .target(name: "Libraries", dependencies: []),
        .target(name: "Machines", dependencies: ["Libraries", "GUSimpleWhiteboard"]),
        .target(name: "MachineLoading", dependencies: ["Machines", "GUSimpleWhiteboard"]),
        .target(name: "Scheduling", dependencies: ["Machines", "MachineLoading", "GUSimpleWhiteboard"]),
        .target(name: "Parsing", dependencies: ["Scheduling"]),
        .target(name: "Verification", dependencies: ["IO", "Machines", "Scheduling"]),
        .target(name: "CFSMWrappers", dependencies: ["GUSimpleWhiteboard", "Libraries", "Scheduling"]),
        .target(
            name: "swiftfsm",
            dependencies: [
                "GUSimpleWhiteboard",
                "IO",
                "CFSMs",
                "swiftfsm_helpers",
                "Libraries",
                "Machines",
                "MachineLoading",
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
