import FSM

public extension FSMInformation {

    /// Create a new FSMInformation from a model of a finite state machine.
    ///
    /// - Parameter fsm: The model of the finite state machine that will be inspected to produce the metadata associated with it.
    init<FSM: Model.FSM>(fsm: FSM) {
        let id = IDRegistrar.id(of: fsm.name)
        self.init(id: id, name: fsm.name, dependencies: fsm.dependencies)
    }

}
