let foundationDeps: [Target.Dependency] = [.byName(name: "swift_helpers")]
let deps = [
    .package(url: "ssh://git.mipal.net/git/swift_helpers.git", .branch("master"))
] + normalDependencies
