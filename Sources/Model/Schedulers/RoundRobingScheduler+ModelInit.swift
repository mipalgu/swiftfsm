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
    init<Schedule: ScheduleProtocol>(
        schedule: Schedule,
        parameters: [String: any DataStructure],
        contexts: UnsafeMutablePointer<SchedulerContextProtocol>,
        data dataPtr: UnsafeMutablePointer<ErasedFiniteStateMachineData>
    ) {
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
            dataPtr.advanced(by: index).initialize(to: fsm.make(schedule.arrangement))
            dataPtr[index].initialiseContext(
                parameters: parameters[newInfo.name],
                context: contexts.advanced(by: index)
            )
            let slot = SlotData(
                info: newInfo,
                executable: dataPtr[index].executable,
                context: contexts.advanced(by: index)
            ) {
                dataPtr[index].initialiseContext(parameters: $0, context: $1)
            }
            slots.append(slot)
        }
        self.init(map: Map(slots: slots))
    }

}
