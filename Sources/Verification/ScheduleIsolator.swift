import KripkeStructureViews

/// Is responsible for splitting a schedule into discrete verifiable
/// subcomponents based on the communication lines between fsms.
public struct ScheduleIsolator {

    private var parameterisedThreads: [Int: IsolatedThread]

    var threads: [IsolatedThread]

    var cycleLength: Duration

    public init(schedule: Schedule, pool: ExecutablePool) {
        if !schedule.isValid(forPool: pool) {
            fatalError("Cannot partition an invalid schedule.")
        }
        var schedules = schedule.threads.flatMap {
            $0.sections.flatMap { section -> [ScheduleThread] in
                section.timeslots.map {
                    ScheduleThread(
                        sections: [
                            SnapshotSection(
                                startingTime: section.startingTime,
                                duration: section.duration,
                                timeslots: [$0]
                            )
                        ]
                    )
                }
            }
        }
        var i = 0
        outerLoop: while i < (schedules.count - 1) {
            for j in (i + 1)..<schedules.count where schedules[i].sharesDependencies(with: schedules[j]) {
                if schedules[i].willOverlapUnlessSame(schedules[j]) {
                    fatalError("Detected overlapping schedules that should be combined")
                }
                schedules[i].merge(schedules[j])
                schedules.remove(at: j)
                continue outerLoop
            }
            i += 1
        }
        var parameterisedThreads: [Int: IsolatedThread] = [:]
        // for i in (schedules.count - 1)...0 {
        //     let fsms = Set(schedules[i].sections.flatMap(\.timeslots).flatMap(\.executables))
        //     if fsms.contains(where: { allFsms.executable($0).parameters == nil }) {
        //         continue
        //     }
        //     let parameterised = fsms.filter { allFsms.fsm($0).parameters != nil }
        //     let map = schedules[i].verificationMap(delegates: [])
        //     parameterised.forEach {
        //         parameterisedThreads[$0] = IsolatedThread(
        //             map: map,
        //             pool: FSMPool(fsms: parameterised.map { allFsms.fsm($0).clone() }, parameterisedFSMs: [])
        //         )
        //     }
        //     schedules.remove(at: i)
        // }
        let isolatedThreads: [IsolatedThread] = schedules.map {
            let fsms = Set($0.sections.flatMap(\.timeslots).flatMap(\.executables))
            let pool = ExecutablePool(executables: fsms.map {
                let element = pool.executables[pool.index(of: $0)]
                return (element.information, (element.context.cloned, element.executableType))
            })
            return IsolatedThread(map: $0.verificationMap(delegates: []), pool: pool)
        }
        self.init(
            threads: isolatedThreads,
            parameterisedThreads: parameterisedThreads,
            cycleLength: schedule.cycleLength
        )
    }

    init(
        threads: [IsolatedThread],
        parameterisedThreads: [Int: IsolatedThread],
        cycleLength: Duration
    ) {
        self.threads = threads
        self.parameterisedThreads = parameterisedThreads
        self.cycleLength = cycleLength
    }

    func thread(forFsm fsm: Int) -> IsolatedThread? {
        parameterisedThreads[fsm]
    }

    public func generateKripkeStructures(formats: Set<View>, usingClocks: Bool) throws {
        let verifier = ScheduleVerifier(isolatedThreads: self)
        let structures = try verifier.verify()
        if formats.isEmpty {
            return
        }
        let factory = AggregateKripkeStructureViewFactory(factories: formats.map(\.factory))
        for structure in structures {
            let view = factory.make(identifier: structure.identifier)
            try view.generate(store: structure, usingClocks: usingClocks)
        }
    }

}

extension Dictionary where Value: RangeReplaceableCollection {

    mutating func insert(_ value: Value.Element, into key: Key) {
        if self[key] == nil {
            self[key] = Value([value])
        } else {
            self[key]?.append(value)
        }
    }

}

extension Dictionary where Value: SetAlgebra {

    mutating func insert(_ value: Value.Element, into key: Key) {
        if self[key] == nil {
            var collection = Value()
            collection.insert(value)
            self[key] = collection
        } else {
            self[key]?.insert(value)
        }
    }

}
