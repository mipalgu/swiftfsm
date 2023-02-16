/// A data structure that contains metadata associated with a single finite state machine.
public struct FSMInformation: DataStructure {

    /// The unique identifier of the finite state machine.
    public let id: Int

    /// The name of the finite state machine.
    public let name: String

    /// Information relating to the relationships that this finite state machine has with other finite state machines within the arrangement in which
    /// it belongs.
    public let dependencies: [FSMDependency]

    /// Create a new FSMInformation from a model of a finite state machine.
    ///
    /// - Parameter fsm: The model of the finite state machine that will be inspected to produce the metadata associated with it.
    public init<FSM: FSMModel>(fsm: FSM) {
        let id = IDRegistrar.id(of: fsm.name)
        self.init(id: id, name: fsm.name, dependencies: fsm.dependencies)
    }

    /// Create a new FSMInformation.
    ///
    /// - Parameter id: The unique identifier of the finite state machine.
    ///
    /// - Parameter name: The name of the finite state machine.
    ///
    /// - Parameter dependencies: Information relating to the relationships that this finite state machine has with other finite state machines
    /// within the arrangement in which this finite state machine belongs.
    init(id: Int, name: String, dependencies: [FSMDependency]) {
        self.id = id
        self.name = name
        self.dependencies = dependencies
    }

}
