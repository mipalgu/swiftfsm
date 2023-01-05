public struct RoundRobinScheduler {

    public func run<Arrangement: ArrangementModel>(arrangement: Arrangement, parameters: [String: any DataStructure]) {
        var executables: [Executable] = []
        var data: [Sendable] = []
        func setup() {
            let groups = arrangement.groups
            guard let group = groups.first else {
                return
            }
            guard groups.count <= 1 else {
                fatalError("Parallel execution has not yet been implemented.")
            }
            let slots = group.slots
            guard !slots.isEmpty else {
                return
            }
            let models = Dictionary(uniqueKeysWithValues: arrangement.fsms.map {
                ($0.projectedValue.id, $0.wrappedValue)
            })
            let executingFSMs = Set(group.slots.map(\.fsm))
            var fsms: Set<Int> = []
            let executablesAndData: [(Executable, Sendable)] = executingFSMs.compactMap {
                guard let model = models[$0.id] else {
                    fatalError("Unable to fetch model for fsm \($0.name).")
                }
                guard !fsms.contains($0.id) else {
                    return nil
                }
                return model.fsm(parameters: parameters[$0.name])
            }
        }
    }

}
