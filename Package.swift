// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swiftfsm",
    products: [
        .library(
            name: "IO",
            targets: ["IO"]
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
        .target(name: "swiftfsm", dependencies: ["GUSimpleWhiteboard", "IO", "CFSMs", "swiftfsm_helpers"]),
        .testTarget(name: "swiftfsmTests", dependencies: [.target(name: "swiftfsm")])
    ]
)
