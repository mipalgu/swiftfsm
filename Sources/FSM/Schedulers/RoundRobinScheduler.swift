public struct RoundRobinScheduler {

    // public func run<Arrangement: ArrangementModel>(arrangement: Arrangement, parameters: [String: any DataStructure]) {
    //     func setup() -> (Executable, AnySchedulerContext) {
    //         let groups = arrangement.groups
    //         guard let group = groups.first else {
    //             return
    //         }
    //         guard groups.count <= 1 else {
    //             fatalError("Parallel execution has not yet been implemented.")
    //         }
    //         let slots = group.slots
    //         guard !slots.isEmpty else {
    //             return
    //         }
    //         var ids: [Int: Int] = [:]
    //         var latestID = 0
    //         func id(for oldID: Int) -> Int {
    //             if let id = ids[oldID] {
    //                 return id
    //             } else {
    //                 let newID = latestID
    //                 latestID = latestID &+ 1
    //                 ids[oldID] = newID
    //                 return newID
    //             }
    //         }
    //         let initialData = arrangement.fsms.enumerated().map { (index, fsm) in
    //             let (fsm, context) = fsm.wrappedValue.initialConfiguration(parameters: nil)
    //             return 
    //         }
    //         let executingFSMs = Set(group.slots.map(\.fsm))
    //         var fsms: Set<Int> = []
    //         let executablesAndData: [(Executable, Sendable)] = executingFSMs.compactMap {
    //             guard let model = models[$0.id] else {
    //                 fatalError("Unable to fetch model for fsm \($0.name).")
    //             }
    //             guard !fsms.contains($0.id) else {
    //                 return nil
    //             }
    //             return model.fsm(parameters: parameters[$0.name])
    //         }
    //     }
    // }

}
