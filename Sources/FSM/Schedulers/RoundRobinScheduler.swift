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
        func setup() {
            var ids: [Int: Int] = [:]
            for fsm in schedule.arrangement.fsms {
                let actualID = executables.count
                let oldID = fsm.projectedValue.id
                if let id = ids[oldID] {
                    let oldInfo = info[id]
                    info.append(
                        FSMInformation(id: actualID, name: oldInfo.name, dependencies: oldInfo.dependencies)
                    )
                    executables.append(executables[id])
                    contexts.append(contexts[id])
                    dataFactories.append(dataFactories[id])
                    continue
                }
                ids[oldID] = actualID
                let oldInfo = fsm.projectedValue
                let newInfo = FSMInformation(
                    id: actualID,
                    name: oldInfo.name,
                    dependencies: oldInfo.dependencies
                )
                let initialConfiguration = fsm.wrappedValue.initial
                let executable = initialConfiguration.0
                let factory = initialConfiguration.1
                let initialData = factory(parameters[newInfo.name])
                executables.append(executable)
                dataFactories.append(factory)
                contexts.append(initialData)
            }
        }
        setup()
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
