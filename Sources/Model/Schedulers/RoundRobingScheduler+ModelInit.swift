import FSM

public extension RoundRobinScheduler {

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
    init<Schedule: ScheduleProtocol>(schedule: Schedule, parameters: [String: any DataStructure]) {
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
            let (executable, contextFactory) = fsm.initial
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

}
