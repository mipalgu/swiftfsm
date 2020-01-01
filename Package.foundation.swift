let foundationDeps: [Target.Dependency] = [.byName(name: "Machines"), .byName(name: "IO")]
let deps = [
    .package(url: "ssh://git.mipal.net/git/Machines.git", .branch("master")),
    .package(url: "ssh://git.mipal.net/git/swift_helpers.git", .branch("master"))
] + normalDependencies
