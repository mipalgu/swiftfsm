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
        .target(name: "Gateways", dependencies: ["swift_helpers"]),
        .target(name: "Timers", dependencies: ["swiftfsm_helpers"]),
        .target(name: "Libraries", dependencies: ["IO"]),
        .target(name: "MachineStructure", dependencies: convert(["Libraries", "GUSimpleWhiteboard", "Timers"]) + foundationDeps),
        .target(name: "MachineLoading", dependencies: convert(["Libraries", "Gateways", "GUSimpleWhiteboard", "IO", "swift_helpers", "swiftfsm_helpers"]) + foundationDeps),
        .target(name: "MachineCompiling", dependencies: convert(["IO"]) + foundationDeps),
        .target(name: "Scheduling", dependencies: ["MachineStructure", "MachineLoading", "Timers", "GUSimpleWhiteboard", "Gateways"]),
        .target(name: "Verification", dependencies: ["IO", "MachineStructure", "Scheduling", "Timers", "Gateways", "swift_helpers"]),
        .target(name: "Parsing", dependencies: ["Scheduling", "Timers", "Verification"]),
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
                "CFSMWrappers",
                "Gateways"
            ]
        ),
        .testTarget(name: "VerificationTests", dependencies: [.target(name: "Verification")]),
        .testTarget(name: "swiftfsmTests", dependencies: [.target(name: "swiftfsm_bin")])
    ]
)
