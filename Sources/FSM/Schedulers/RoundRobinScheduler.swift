public struct RoundRobinScheduler {

    private struct Map {

        var slots: [SlotData]

    }

    private final class SlotData {

        var info: FSMInformation

        var executable: Executable

        var context: AnySchedulerContext

        var contextFactory: ((any DataStructure)?) -> AnySchedulerContext

        var isFinished: Bool {
            executable.isFinished(context: context)
        }

        var isSuspended: Bool {
            executable.isSuspended(context: context)
        }


        var shouldTerminate: Bool {
            isFinished || isSuspended
        }

        fileprivate init(
            info: FSMInformation,
            executable: Executable,
            context: AnySchedulerContext,
            contextFactory: @escaping ((any DataStructure)?) -> AnySchedulerContext
        ) {
            self.info = info
            self.executable = executable
            self.context = context
            self.contextFactory = contextFactory
        }

        func next() {
            executable.next(context: context)
        }

        func takeSnapshot() {
            executable.takeSnapshot(context: context)
        }

        func saveSnapshot() {
            executable.saveSnapshot(context: context)
        }

    }

    /// Contains information regarding the executables that this scheduler
    /// executes.
    private var map: Map

    public init<Schedule: ScheduleModel>(schedule: Schedule, parameters: [String: any DataStructure]) {
        var slots: [SlotData] = []
        let fsms = schedule.arrangement.fsms
        slots.reserveCapacity(fsms.count)
        for (index, fsm) in fsms.enumerated() {
            let oldInfo = fsm.projectedValue
            let newInfo = FSMInformation(
                id: index,
                name: oldInfo.name,
                dependencies: oldInfo.dependencies
            )
            let (executable, contextFactory) = fsm.wrappedValue.initial
            let initialData = contextFactory(parameters[newInfo.name])
            let slot = SlotData(info: newInfo, executable: executable, context: initialData, contextFactory: contextFactory)
            slots.append(slot)
        }
        self.init(map: Map(slots: slots))
    }

    private init(map: Map) {
        self.map = map
    }

    public private(set) var shouldTerminate: Bool = false

    public mutating func cycle() {
        shouldTerminate = true
        for slot in map.slots {
            slot.takeSnapshot()
            slot.next()
            slot.saveSnapshot()
            shouldTerminate = slot.shouldTerminate
        }
    }

}
