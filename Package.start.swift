// swift-tools-version:4.0

import PackageDescription

let normalDependencies: [Package.Dependency] = [
    .package(url: "ssh://git.mipal.net/git/swift_CLReflect.git", .branch("master"))
]

func convert(_ arr: [String]) -> [Target.Dependency] {
    return arr.map {.byName(name: $0) }
}
