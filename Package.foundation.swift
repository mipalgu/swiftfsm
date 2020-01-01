let foundationDeps: [Target.Dependency] = [.byName(name: "Machines"), .buName(name: "IO")]
let deps = [
    .package(url: "ssh://git.mipal.net/git/Machines.git", .branch("master")),
] + normalDependencies
