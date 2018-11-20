// swift-tools-version:4.0

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(url: "ssh://git.mipal.net/git/swift_wb.git", .branch("swift-4.2")),
    .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master")),
    .package(url: "ssh://git.mipal.net/git/swift_helpers.git", .branch("master"))
]

func convert(_ arr: [String]) -> [Target.Dependency] {
    return arr.map {.byName(name: $0) }
}
