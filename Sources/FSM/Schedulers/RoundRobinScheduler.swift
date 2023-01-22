public struct RoundRobinScheduler {

    private var info: [FSMInformation]

    private var executables: [Executable]

    private var contexts: [AnySchedulerContext]

    private var dataFactories: [((any DataStructure)?) -> AnySchedulerContext]

    public init<Schedule: ScheduleModel>(schedule: Schedule, parameters: [String: any DataStructure]) {
        var info: [FSMInformation] = []
        var executables: [Executable] = []
        var contexts: [AnySchedulerContext] = []
        var dataFactories: [((any DataStructure)?) -> AnySchedulerContext] = []
        let fsms = schedule.arrangement.fsms
        info.reserveCapacity(fsms.count)
        executables.reserveCapacity(fsms.count)
        contexts.reserveCapacity(fsms.count)
        dataFactories.reserveCapacity(fsms.count)
        for fsm in fsms {
            let actualID = executables.count
            let oldInfo = fsm.projectedValue
            let newInfo = FSMInformation(
                id: actualID,
                name: oldInfo.name,
                dependencies: oldInfo.dependencies
            )
            let (executable, factory) = fsm.wrappedValue.initial
            let initialData = factory(parameters[newInfo.name])
            info.append(newInfo)
            executables.append(executable)
            dataFactories.append(factory)
            contexts.append(initialData)
        }
        self.init(info: info, executables: executables, contexts: contexts, dataFactories: dataFactories)
    }

    private init(
        info: [FSMInformation],
        executables: [Executable],
        contexts: [AnySchedulerContext],
        dataFactories: [((any DataStructure)?) -> AnySchedulerContext]
    ) {
        self.info = info
        self.executables = executables
        self.contexts = contexts
        self.dataFactories = dataFactories
    }

    public func cycle() {
        var isFinished = true
        while !isFinished {
            isFinished = true
            for (index, executable) in executables.enumerated() {
                executable.takeSnapshot(context: contexts[index])
                executable.next(context: contexts[index])
                executable.saveSnapshot(context: contexts[index])
            }
        }
    }

}
