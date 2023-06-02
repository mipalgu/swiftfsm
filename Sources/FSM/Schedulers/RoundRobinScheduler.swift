/// A scheduler that executes an particular schedule in round robin.
public struct RoundRobinScheduler {

    /// A data structure that contains relevent information about the schedule
    /// that this scheduler executes.
    ///
    /// This data structure is generally useful as aspects of the schedule can
    /// be computed apriori and thus allow for a more optimal execution of the
    /// schedule.
    private struct Map {

        /// The slots that this scheduler is executing.
        var slots: [SlotData]

    }

    /// A convenience data structure that contains relevent information about
    /// an individual slot with a schedule.
    ///
    /// This data structure is useful as aspects of the slot can be computed
    /// apriori before executing the schedule and thus allows for a more optimal
    /// execution of the schedule.
    private final class SlotData {

        /// Meta data relating to the fsm that is executed by this slot.
        ///
        /// This property contains information such as the unique identifier of
        /// the fsm, as well as the fsms name.
        let info: FSMInformation

        /// A type-erased type that represents something (such as an FSM) that
        /// can be executed by this scheduler.
        ///
        /// This property is closely tied to `context` in that `context` defines
        /// the data or state of a particular slot; whereas, this property
        /// defines the method of execution that manipulates the `context` data.
        let executable: Executable

        /// Any data associated with `executable`.
        ///
        /// This property is closely related to `executable` in that this
        /// context models the state of the `executable`. The `executable`
        /// defines the method of execution that manipulates this context.
        let context: AnySchedulerContext

        /// A function that creates a new `context` associated with `executable`
        /// from a type-erased list of parameters.
        let contextFactory: ((any DataStructure)?) -> AnySchedulerContext

        /// Does `context` represent a state where the `executable` is finished?
        @inlinable var isFinished: Bool {
            executable.isFinished(context: context)
        }

        /// Does `context` represent a state where the `executable` is
        /// suspended?
        @inlinable var isSuspended: Bool {
            executable.isSuspended(context: context)
        }

        /// Is this slot in a configuration where, if the slot was the only
        /// slot within the schedule, then the schedule should terminate?
        @inlinable var shouldTerminate: Bool {
            isFinished || isSuspended
        }

        /// Create a new SlotData.
        ///
        /// - Parameter info: Any metadata associated with this slot.
        ///
        /// - Parameter executable: The entity that can be executed within this
        /// slot.
        ///
        /// - Parameter context: The state data associated with the executable.
        ///
        /// - Parameter contextFactory: A function that creates a new context
        /// from a type-erased parameter list.
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

        /// Execute a single ringlet of `executable`.
        @inlinable
        func next() {
            executable.next(context: context)
        }

        /// Take a snapshot of all environment variables and store the snapshot
        /// within `context`.
        @inlinable
        func takeSnapshot() {
            executable.takeSnapshot(context: context)
        }

        /// Save the snasphot within `context` back out to the environment.
        @inlinable
        func saveSnapshot() {
            executable.saveSnapshot(context: context)
        }

    }

    /// Contains information regarding the executables that this scheduler
    /// executes.
    private var map: Map

    /// Has this scheduler executed the schedule to completion?
    public private(set) var shouldTerminate = false

    /// Create a new RoundRobinScheduler by inspecting a model of a particular
    /// schedule containing a model of an arrangement, containing models of
    /// FSMs.
    ///
    /// - Parameter schedule: The schedule containing all models that will be
    /// inspected to create this scheduler.
    ///
    /// - Parameter parameters: A key-value pairing of type-erased parameter
    /// lists associated with particular FSMs. The key of the dictionary
    /// represents the unique name of a particular FSM, and the value contains
    /// a type-erased data structure representing the parameters.
    public init<Schedule: ScheduleProtocol>(schedule: Schedule, parameters: [String: any DataStructure]) {
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
            let slot = SlotData(
                info: newInfo,
                executable: executable,
                context: initialData,
                contextFactory: contextFactory
            )
            slots.append(slot)
        }
        self.init(map: Map(slots: slots))
    }

    /// Create a new RoundRobinScheduler.
    ///
    /// - Parameter map: The pre-computed map of the schedule that this
    /// scheduler executes.
    private init(map: Map) {
        self.map = map
    }

    /// Execute a single iteration of the schedule that is being executed by
    /// this scheduler.
    public mutating func cycle() {
        shouldTerminate = true
        for slot in map.slots {
            slot.takeSnapshot()
            slot.next()
            slot.saveSnapshot()
            shouldTerminate = shouldTerminate && slot.shouldTerminate
        }
    }

}
