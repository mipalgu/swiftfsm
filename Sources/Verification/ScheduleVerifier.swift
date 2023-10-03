import FSM
import KripkeStructure

final class ScheduleVerifier {

    private struct Previous {

        var id: Int64

        var time: UInt

        func afterExecutingTimeUntil(time: UInt, cycleLength: UInt) -> UInt {
            let currentTime = self.time
            if time >= currentTime {
                return time - currentTime
            } else {
                return (cycleLength - currentTime) + time
            }
        }

    }

    private struct Job {

        var initial: Bool {
            previous == nil
        }

        var step: Int

        var map: VerificationMap

        var pool: ExecutablePool

        var cycleCount: UInt

        //var promises: [String: PromiseData]

        var previousNodes: Set<Int64>

        var previous: Previous?

        var resetClocks: Set<Int>?

    }

    private final class JobRef {

        var job: Job

        init(_ job: Job) {
            self.job = job
        }

    }

    let isolatedThreads: ScheduleIsolator

    private var resultsCache: [CallKey: CallResults] = [:]

    private var stores: [Int: Any] = [:]

    convenience init(schedule: Schedule, pool: ExecutablePool) {
        self.init(isolatedThreads: ScheduleIsolator(schedule: schedule, pool: pool))
    }

    init(isolatedThreads: ScheduleIsolator) {
        self.isolatedThreads = isolatedThreads
    }

    func verify() throws -> [SQLiteKripkeStructure] {
        try self.verify(factory: SQLiteKripkeStructureFactory())
    }

    func verify<Factory: MutableKripkeStructureFactory>(factory: Factory)
    throws -> [Factory.KripkeStructure] {
        stores = [:]
        resultsCache = [:]
        for (index, thread) in isolatedThreads.threads.enumerated() {
            let allFsmIds: Set<Int> = Set(thread.map.steps.flatMap {
                $0.step.timeslots.flatMap(\.executables)
            })
            let filtered = allFsmIds // .filter { !thread.pool.parameterisedFSMs.keys.contains($0) }
            let identifier = filtered.count == 1 ? filtered.first ?? index : index
            try verify(thread: thread, identifier: identifier, factory: factory, recordingResultsFor: nil)
        }
        return stores.values.map { $0 as! Factory.KripkeStructure }
    }

    @discardableResult
    func verify<Factory: MutableKripkeStructureFactory>(
        thread: IsolatedThread,
        identifier: Int,
        factory: Factory,
        recordingResultsFor resultsFsm: Int?
    ) throws -> CallResults {
        let persistentStore = try (stores[identifier] as? Factory.KripkeStructure)
            ?? factory.make(identifier: String(identifier))
        defer { self.stores[identifier] = persistentStore }
        var callResults = CallResults()
        if thread.map.steps.isEmpty {
            if let resultsFsm = resultsFsm {
                fatalError("Thread is empty for calling \(resultsFsm)")
            }
            return callResults
        }
        let generator = VerificationStepGenerator()
        // gateway.setScenario([], pool: thread.pool)
        var cyclic: Bool?
        let collapse = !thread.map.steps.contains { $0.step.executables.count > 1 }
        var jobs = [
            JobRef(
                Job(
                    step: 0,
                    map: thread.map,
                    pool: thread.pool,
                    cycleCount: 0,
                    // promises: [:],
                    previousNodes: [],
                    previous: nil,
                    resetClocks: Set(thread.pool.executables.map(\.information.id))
                        // .filter { thread.pool.parameterisedFSMs[$0] == nil })
                )
            )
        ]
        jobs.reserveCapacity(100_000)
        while !jobs.isEmpty {
            let job = jobs.removeLast().job
            let step = job.map.steps[job.step]
            let previous = job.previous
            let newStep = job.step >= (job.map.steps.count - 1) ? 0 : job.step + 1
            // Handle Delegate steps.
            delegateSwitch: switch step.step {
            case .startDelegates, .takeSnapshotAndStartTimeslot, .startTimeslot:
                switch step.step {
                case .takeSnapshotAndStartTimeslot(let timeslot), .startTimeslot(let timeslot):
                    if timeslot.callChain.calls.isEmpty {
                        break delegateSwitch
                    }
                default:
                    break
                }
                let timeslots = step.step.timeslots
                var previous = previous
                var resetClocks = job.resetClocks
                var allInCycle = true
                var subCycle = false
                var previousNodes = job.previousNodes
                for timeslot in timeslots.sorted(by: { $0.callChain.executable < $1.callChain.executable }) {
                    let shouldReset = resetClocks?.contains(timeslot.callChain.executable)
                    resetClocks?.subtract([timeslot.callChain.executable])
                    let properties = job.pool.propertyList(
                        forStep: .startDelegates(timeslots: [timeslot]),
                        executingState: nil,
                        // promises: job.promises,
                        resetClocks: resetClocks,
                        collapseIfPossible: collapse
                    )
                    let inCycle = try persistentStore.exists(properties)
                    allInCycle = allInCycle && inCycle
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: job.initial)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
                    }
                    subCycle = subCycle || previousNodes.contains(id)
                    previousNodes.formUnion([id])
                    if let previous = previous {
                        let edge = KripkeEdge(
                            clockName: "fsm\(timeslot.callChain.executable)",
                            constraint: nil,
                            resetClock: shouldReset ?? false,
                            takeSnapshot: true,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time.timeValue,
                                cycleLength: isolatedThreads.cycleLength.timeValue
                            ),
                            target: properties
                        )
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    previous = Previous(id: id, time: step.time.timeValue)
                }
                guard !allInCycle else {
                    if let resultsFsm = resultsFsm {
                        if subCycle {
                            // swiftlint:disable:next line_length
                            fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                        }
                        guard let c = cyclic else {
                            cyclic = true
                            continue
                        }
                        guard c else {
                            // swiftlint:disable:next line_length
                            fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                        }
                        cyclic = true
                    }
                    continue
                }
                let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                jobs.append(
                    JobRef(
                        Job(
                            step: newStep,
                            map: job.map,
                            pool: job.pool,
                            cycleCount: newCycleCount,
                            // promises: job.promises,
                            previousNodes: previousNodes,
                            previous: previous,
                            resetClocks: resetClocks
                        )
                    )
                )
                continue
            case .endDelegates, .execute, .executeAndSaveSnapshot:
                switch step.step {
                case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                    if timeslot.callChain.calls.isEmpty {
                        break delegateSwitch
                    }
                default:
                    break
                }
                let timeslots = step.step.timeslots
                let executing: [Timeslot] = []
                    // timeslots.filter { job.pool.parameterisedFSMs[$0.callChain.fsm]?.status == .executing }
                let remainingTimeslots = timeslots.subtracting(executing)
                let pathways = try processDelegate(
                    factory: factory,
                    time: step.time,
                    map: job.map,
                    pool: job.pool,
                    // promises: job.promises,
                    resetClocks: job.resetClocks,
                    previous: job.previous,
                    timeslots: executing,
                    addingTo: persistentStore,
                    collapse: collapse
                )
                var newPrevious: [Previous] = []
                if !remainingTimeslots.isEmpty {
                    let pathways = pathways.isEmpty
                        ? [(job.pool, job.map, [job.previous])]
                        : pathways
                    for (pool, map, previous) in pathways {
                        let properties = pool.propertyList(
                            forStep: .endDelegates(timeslots: remainingTimeslots),
                            executingState: nil,
                            // promises: job.promises,
                            resetClocks: job.resetClocks,
                            collapseIfPossible: collapse
                        )
                        let inCycle = try persistentStore.exists(properties)
                        let id: Int64
                        if !inCycle {
                            id = try persistentStore.add(properties, isInitial: false)
                        } else {
                            id = try persistentStore.id(for: properties)
                        }
                        var previousNodes = job.previousNodes
                        for previous in previous {
                            if let previous = previous {
                                let edge = KripkeEdge(
                                    clockName: nil,
                                    constraint: nil,
                                    resetClock: false,
                                    takeSnapshot: false,
                                    time: previous.afterExecutingTimeUntil(
                                        time: step.time.timeValue,
                                        cycleLength: isolatedThreads.cycleLength.timeValue
                                    ),
                                    target: properties
                                )
                                try persistentStore.add(edge: edge, to: previous.id)
                                previousNodes.formUnion([previous.id])
                                newPrevious.append(previous)
                            }
                        }
                        guard !inCycle else {
                            if let resultsFsm = resultsFsm {
                                guard let c = cyclic else {
                                    if job.previousNodes.contains(id) {
                                        cyclic = true
                                    }
                                    continue
                                }
                                if !job.previousNodes.contains(id) {
                                    continue
                                }
                                guard c else {
                                    // swiftlint:disable:next line_length
                                    fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                                }
                            }
                            continue
                        }
                        let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                        let newPrevious = Previous(id: id, time: step.time.timeValue)
                        jobs.append(
                            JobRef(
                                Job(
                                    step: newStep,
                                    map: map,
                                    pool: pool,
                                    cycleCount: newCycleCount,
                                    // promises: job.promises,
                                    previousNodes: previousNodes.union([id]),
                                    previous: newPrevious,
                                    resetClocks: job.resetClocks
                                )
                            )
                        )
                    }
                } else {
                    for (pool, map, previous) in pathways {
                        for previous in previous {
                            if let previous = previous {
                                let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                                jobs.append(
                                    JobRef(
                                        Job(
                                            step: newStep,
                                            map: map,
                                            pool: pool,
                                            cycleCount: newCycleCount,
                                            // promises: job.promises,
                                            previousNodes: job.previousNodes.union([previous.id]),
                                            previous: previous,
                                            resetClocks: job.resetClocks
                                        )
                                    )
                                )
                            }
                        }
                    }
                }
                continue
            default:
                break
            }
            // Handle inline steps.
            switch step.step {
            case .takeSnapshot, .takeSnapshotAndStartTimeslot, .startTimeslot, .saveSnapshot:
                let fsms = step.step.timeslots.filter { !job.map.delegates.contains($0.callChain.executable) }
                let startTimeslot = step.step.startTimeslot
                let fsm = startTimeslot
                    ? (fsms.first?.callChain.executable).map { job.pool.executables[job.pool.index(of: $0)] }
                    : nil
                let pools: [ExecutablePool]
                if step.step.takeSnapshot {
                    pools = generator.takeSnapshot(
                        forFsms: fsms.map {
                            job.pool.executables[job.pool.index(of: $0.callChain.executable)]
                                .verificationContext
                        },
                        in: job.pool
                    )
                } else {
                    pools = [job.pool]
                }
                let newResetClocks: Set<Int>?
                let shouldReset: Bool
                if startTimeslot, let timeslot = fsms.first {
                    shouldReset = job.resetClocks?.contains(timeslot.callChain.executable) ?? false
                    newResetClocks = job.resetClocks?.subtracting([timeslot.callChain.executable])
                } else {
                    newResetClocks = job.resetClocks
                    shouldReset = false
                }
                for pool in pools {
                    // swiftlint:disable:next line_length
                    // print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(pool)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                    let properties = pool.propertyList(
                        forStep: step.step,
                        executingState: (fsm?.context.currentState)
                            .flatMap { fsm?.executable.state($0).name },
                        // promises: job.promises,
                        resetClocks: newResetClocks,
                        collapseIfPossible: collapse
                    )
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
                    }
                    if let previous = previous {
                        let edge = KripkeEdge(
                            clockName: fsm.map { "fsm\($0.information.id)" },
                            constraint: nil,
                            resetClock: shouldReset,
                            takeSnapshot: startTimeslot,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time.timeValue,
                                cycleLength: isolatedThreads.cycleLength.timeValue
                            ),
                            target: properties
                        )
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: pool) {
                        if let resultsFsm = resultsFsm {
                            guard pool.executable(resultsFsm).isParameterised else {
                                fatalError("Attempting to record results for a non-parameterised fsm")
                            }
                            let context = pool.context(resultsFsm)
                            callResults.insert(
                                result: context.typeErasedResult,
                                forTime: job.cycleCount * isolatedThreads.cycleLength.timeValue
                                    + step.time.timeValue
                            )
                            guard let c = cyclic else {
                                cyclic = false
                                continue
                            }
                            guard !c else {
                                fatalError("Attempting to record results for a cyclic fsm.")
                            }
                            cyclic = false
                        }
                        continue
                    }
                    guard !inCycle else {
                        if let resultsFsm = resultsFsm {
                            guard let c = cyclic else {
                                if job.previousNodes.contains(id) {
                                    cyclic = true
                                }
                                continue
                            }
                            if !job.previousNodes.contains(id) {
                                continue
                            }
                            guard c else {
                                // swiftlint:disable:next line_length
                                fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                            }
                        }
                        continue
                    }
                    let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                    let newPrevious = Previous(id: id, time: step.time.timeValue)
                    // let newPromises = job.promises.filter { !properties.contains(object: $1) }
                    jobs.append(
                        JobRef(
                            Job(
                                step: newStep,
                                map: job.map,
                                pool: pool.cloned,
                                cycleCount: newCycleCount,
                                // promises: newPromises,
                                previousNodes: job.previousNodes.union([id]),
                                previous: newPrevious,
                                resetClocks: newResetClocks
                            )
                        )
                    )
                }
            case .execute(let timeslot), .executeAndSaveSnapshot(let timeslot):
                let fsm = job.pool.executables[job.pool.index(of: timeslot.callChain.executable)]
                let currentState = fsm.executable.state(fsm.context.currentState).name
                let ringlets = generator.execute(
                    timeslot: timeslot,
                    // promises: job.promises,
                    inPool: job.pool
                )
                for ringlet in ringlets {
                    // swiftlint:disable:next line_length
                    // print("\nGenerating \(step.step.marker)(\(step.step.timeslots.map(\.callChain.fsm).sorted().joined(separator: ", "))) variations for:\n    \("\(ringlet.after)".components(separatedBy: .newlines).joined(separator: "\n\n    "))\n\n")
                    let newMap = job.map
                    let newPool = ringlet.after
                    // newPool.parameterisedFSMs.merge(job.pool.parameterisedFSMs) { (lhs, _) in lhs }
                    // var callees: Set<String> = []
                    // var newPromises: [String: PromiseData] = [:]
                    // for call in ringlet.calls {
                    //     callees.insert(call.callee.name)
                    //     newPromises[call.callee.name] = call.promiseData
                    //     if job.map.delegates.contains(call.callee.name) {
                    //         newPool.handleCall(to: call.callee.name, parameters: call.parameters)
                    //         newMap.handleCall(call)
                    //     }
                    // }
                    // let mergedPromises = job.promises.merging(newPromises) { (_, _) in
                    //     fatalError("Detected calling same machine more than once.")
                    // }
                    let resetClocks: Set<Int>?
                    if ringlet.transitioned {
                        resetClocks = job.resetClocks.map {
                            $0.union([timeslot.callChain.executable]) // .union(callees)
                        }
                    } else {
                        resetClocks = job.resetClocks // .map { $0.union(callees) }
                    }
                    let properties = newPool.propertyList(
                        forStep: step.step,
                        executingState: currentState,
                        // promises: mergedPromises,
                        resetClocks: resetClocks,
                        collapseIfPossible: collapse
                    )
                    let inCycle = try persistentStore.exists(properties)
                    let id: Int64
                    if !inCycle {
                        id = try persistentStore.add(properties, isInitial: previous == nil)
                    } else {
                        id = try persistentStore.id(for: properties)
                        if job.initial {
                            try persistentStore.markAsInitial(id: id)
                        }
                    }
                    if let previous = previous {
                        let edge = KripkeEdge(
                            clockName: "fsm\(timeslot.callChain.executable)",
                            constraint: ringlet.condition == .lessThanEqual(value: 0)
                                ? nil
                                : ringlet.condition,
                            resetClock: false,
                            takeSnapshot: false,
                            time: previous.afterExecutingTimeUntil(
                                time: step.time.timeValue,
                                cycleLength: isolatedThreads.cycleLength.timeValue
                            ),
                            target: properties
                        )
                        try persistentStore.add(edge: edge, to: previous.id)
                    }
                    if step.step.saveSnapshot && job.map.hasFinished(forPool: ringlet.after) {
                        if let resultsFsm = resultsFsm {
                            guard ringlet.after.executable(resultsFsm).isParameterised else {
                                fatalError("Attempting to record results for a non-parameterised fsm")
                            }
                            let context = ringlet.after.context(resultsFsm)
                            callResults.insert(
                                result: context.typeErasedResult,
                                forTime: job.cycleCount * isolatedThreads.cycleLength.timeValue
                                    + step.time.timeValue
                            )
                            guard let c = cyclic else {
                                cyclic = false
                                continue
                            }
                            guard !c else {
                                fatalError("Attempting to record results for a cyclic fsm")
                            }
                            cyclic = false
                        }
                        continue
                    }
                    guard !inCycle else {
                        if let resultsFsm = resultsFsm {
                            guard let c = cyclic else {
                                if job.previousNodes.contains(id) {
                                    cyclic = true
                                }
                                continue
                            }
                            if !job.previousNodes.contains(id) {
                                continue
                            }
                            guard c else {
                                // swiftlint:disable:next line_length
                                fatalError("Detected cycle in delegate parameterised machine call that should always return a value for call to \(resultsFsm).")
                            }
                        }
                        continue
                    }
                    let newCycleCount = newStep <= job.step ? job.cycleCount + 1 : job.cycleCount
                    let newPrevious = Previous(id: id, time: step.time.timeValue)
                    // let filteredPromises = mergedPromises.filter { !properties.contains(object: $1) }
                    jobs.append(
                        JobRef(
                            Job(
                                step: newStep,
                                map: newMap,
                                pool: newPool,
                                cycleCount: newCycleCount,
                                // promises: filteredPromises,
                                previousNodes: job.previousNodes.union([id]),
                                previous: newPrevious,
                                resetClocks: resetClocks
                            )
                        )
                    )
                }
            case .startDelegates, .endDelegates:
                fatalError("Attempting to handle delegate step in inline step section.")
            }
        }
        return callResults
    }

    private func processDelegate<
        Factory: MutableKripkeStructureFactory,
        C: Collection,
        Structure: MutableKripkeStructure
    >(
        factory: Factory,
        time: Duration,
        map: VerificationMap,
        pool: ExecutablePool,
        // promises: [String: PromiseData],
        resetClocks: Set<Int>?,
        previous: Previous?,
        timeslots: C,
        addingTo structure: Structure,
        collapse: Bool
    ) throws -> [(ExecutablePool, VerificationMap, [Previous?])] where
        C.Element == Timeslot,
        C.SubSequence: Collection,
        C.SubSequence.Element == Timeslot,
        C.SubSequence.SubSequence == C.SubSequence
    {
        print("Attempting to process a delegate which is not yet implemented.")
        return []
        // guard let timeslot = timeslots.first, let call = timeslot.callChain.calls.last else {
        //     return [(pool, map, previous.map { [$0] } ?? [])]
        // }
        // let results = try self.delegate(
        //     call: call,
        //     callee: call.callee.id,
        //     factory: factory
        // )
        // var out: [(ExecutablePool, VerificationMap, [Previous?])] = []
        // for result in results.results {
        //     var resultPool = pool.cloned
        //     resultPool.handleFinishedCall(for: timeslot.callChain.executable, result: result.1)
        //     var newMap = map
        //     newMap.handleFinishedCall(call)
        //     let properties = resultPool.propertyList(
        //         forStep: .endDelegates(fsms: [timeslot]),
        //         executingState: nil,
        //         // promises: promises,
        //         resetClocks: resetClocks,
        //         collapseIfPossible: collapse
        //     )
        //     let inCycle = try structure.exists(properties)
        //     let id: Int64
        //     if !inCycle {
        //         id = try structure.add(properties, isInitial: previous == nil)
        //     } else {
        //         id = try structure.id(for: properties)
        //         if previous == nil {
        //             try structure.markAsInitial(id: id)
        //         }
        //     }
        //     let range = result.0
        //     if let previous = previous {
        //         let edge: KripkeEdge
        //         switch range {
        //         case .greaterThanEqual(let greaterThanTime):
        //             edge = KripkeEdge(
        //                 clockName: "fsm\(timeslot.callChain.executable)",
        //                 constraint: .greaterThanEqual(value: greaterThanTime),
        //                 resetClock: false,
        //                 takeSnapshot: false,
        //                 time: previous.afterExecutingTimeUntil(
        //                     time: time,
        //                     cycleLength: isolatedThreads.cycleLength
        //                 ),
        //                 target: properties
        //             )
        //         case .range(let range):
        //             edge = KripkeEdge(
        //                 clockName: "fsm\(timeslot.callChain.executable)",
        //                 constraint: .and(
        //                     lhs: .greaterThanEqual(value: range.lowerBound),
        //                     rhs: .lessThan(value: range.upperBound)
        //                 ),
        //                 resetClock: false,
        //                 takeSnapshot: false,
        //                 time: previous.afterExecutingTimeUntil(
        //                     time: time,
        //                     cycleLength: isolatedThreads.cycleLength
        //                 ),
        //                 target: properties
        //             )
        //         }
        //         try structure.add(edge: edge, to: previous.id)
        //     }
        //     if inCycle {
        //         continue
        //     }
        //     out.append(
        //         contentsOf: try processDelegate(
        //             factory: factory,
        //             time: time,
        //             map: newMap,
        //             pool: resultPool,
        //             // promises: promises,
        //             resetClocks: resetClocks,
        //             previous: Previous(id: id, time: time),
        //             timeslots: timeslots.dropFirst(),
        //             addingTo: structure,
        //             collapse: collapse
        //         )
        //     )
        // }
        // let properties = pool.propertyList(
        //     forStep: .endDelegates(fsms: [timeslot]),
        //     executingState: nil,
        //     // promises: promises,
        //     resetClocks: resetClocks,
        //     collapseIfPossible: collapse
        // )
        // let inCycle = try structure.exists(properties)
        // let id: Int64
        // if !inCycle {
        //     id = try structure.add(properties, isInitial: previous == nil)
        // } else {
        //     id = try structure.id(for: properties)
        //     if previous == nil {
        //         try structure.markAsInitial(id: id)
        //     }
        // }
        // if let previous = previous {
        //     let extraEdge = KripkeEdge(
        //         clockName: "fsm\(timeslot.callChain.executable)",
        //         constraint: results.results.isEmpty ? nil : .lessThan(value: results.bound),
        //         resetClock: false,
        //         takeSnapshot: false,
        //         time: previous.afterExecutingTimeUntil(
        //             time: time,
        //             cycleLength: isolatedThreads.cycleLength
        //         ),
        //         target: properties
        //     )
        //     try structure.add(edge: extraEdge, to: previous.id)
        // }
        // if inCycle {
        //     return out
        // }
        // out.append(
        //     contentsOf: try processDelegate(
        //         gateway: gateway,
        //         timer: timer,
        //         factory: factory,
        //         time: time,
        //         map: map,
        //         pool: pool,
        //         // promises: promises,
        //         resetClocks: resetClocks,
        //         previous: Previous(id: id, time: time),
        //         timeslots: timeslots.dropFirst(),
        //         addingTo: structure,
        //         collapse: collapse
        //     )
        // )
        // return out
    }

    struct CallResults {

        var bound: UInt = 0

        private var times: SortedCollection = SortedCollection<(UInt, Any?, KripkeStateProperty)> {
            if $0.0 < $1.0 {
                return .orderedAscending
            } else if $0.0 > $1.0 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }

        var results: [(ClockRange, Any?)] {
            if times.isEmpty {
                return []
            }
            let grouped = times.grouped { $0.0 == $1.0 }
            guard let last = grouped.last?.map({ (ClockRange.greaterThanEqual($0.0), $0.1) }) else {
                return []
            }
            if grouped.count == 1 {
                return last
            }
            let zipped = zip(grouped, grouped.dropFirst())
            let ranges = zipped.flatMap { (lhs, rhs) -> [(ClockRange, Any?)] in
                guard let lhsTime = lhs.first?.0, let rhsTime = rhs.first?.0 else {
                    fatalError("Grouped elements results in empty array")
                }
                return lhs.map { (ClockRange.range(lhsTime..<rhsTime), $0.1) }
            }
            return ranges + last
        }

        init() {}

        mutating func insert(result: Sendable?, forTime time: UInt) {
            let plist = KripkeStateProperty(result)
            let element = (time, result, plist)
            let range = times.range(of: element)
            guard !times[range].contains(where: { $0.2 == plist }) else {
                return
            }
            times.insert(element)
            bound = times.last?.0 ?? 0
        }

    }

    enum ClockRange {

        case greaterThanEqual(UInt)
        case range(Range<UInt>)

    }

    struct CallKey: Hashable {

        var callee: Int

        var parameters: [Int: (any DataStructure)?]

        static func == (lhs: CallKey, rhs: CallKey) -> Bool {
            KripkeStatePropertyList(lhs) == KripkeStatePropertyList(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(KripkeStatePropertyList(self))
        }

    }

    private func delegate<Factory: MutableKripkeStructureFactory>(
        call: Call,
        callee: Int,
        factory: Factory
    ) throws -> CallResults {
        let key = CallKey(callee: call.callee.id, parameters: call.parameters)
        if let results = resultsCache[key] {
            return results
        }
        guard var thread = isolatedThreads.thread(forFsm: callee) else {
            fatalError("No thread provided for calling \(callee)")
        }
        // thread.setParameters(of: callee, to: call.parameters)
        let results = try verify(
            thread: thread,
            identifier: callee,
            factory: factory,
            recordingResultsFor: callee
        )
        resultsCache[key] = results
        return results
    }

}
