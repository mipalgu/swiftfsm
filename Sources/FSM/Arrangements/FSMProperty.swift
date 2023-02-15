/// A convenience property wrapper that enables modelling a finite state machine
/// and it's dependencies.
@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementProtocol> {

    /// The metadata associated with the finite state machine.
    /// 
    /// The metadata of a finite state machine contains information such as the
    /// finite state machines name, identifer, and the dependencies that the
    /// finite state machine has to other finite state machines.
    public let projectedValue: FSMInformation

    /// The actual model of the finite state machine that may be utilised to
    /// create the `FiniteStateMachine` that can be executed by a scheduler.
    public let wrappedValue: any FSMModel

    /// Create a new finite state machine property.
    /// 
    /// This initialiser automatically computes the metadata of the finite state
    /// machine.
    /// 
    /// - Parameter wrappedValue: The model of the finite state machine.
    public init<FSM: FSMModel>(wrappedValue: FSM) {
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}
