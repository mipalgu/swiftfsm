import FSM

/// A convenience property wrapper that enables modelling a finite state machine
/// and it's dependencies.
@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementProtocol> {

    private let make: () -> (Executable, ((any DataStructure)?) -> AnySchedulerContext)

    /// The metadata associated with the finite state machine.
    ///
    /// The metadata of a finite state machine contains information such as the
    /// finite state machines name, identifer, and the dependencies that the
    /// finite state machine has to other finite state machines.
    public let projectedValue: FSMInformation

    /// The actual model of the finite state machine that may be utilised to
    /// create the `FiniteStateMachine` that can be executed by a scheduler.
    public let wrappedValue: any FSM

    public var initial: (Executable, ((any DataStructure)?) -> AnySchedulerContext) {
        make()
    }

    /// Create a new finite state machine property.
    ///
    /// This initialiser automatically computes the metadata of the finite state
    /// machine.
    ///
    /// - Parameter wrappedValue: The model of the finite state machine.
    public init<FSM: Model.FSM>(
        actuators: (AnyArrangementActuator, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        externalVariables: (AnyArrangementExternalVariable, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        sensors: (AnyArrangementSensor, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        wrappedValue: FSM
    ) {
        let actuators = Dictionary(
            uniqueKeysWithValues: actuators.lazy.map { ($1, $0.anyActuator(mapsTo: $1)) }
        )
        let externalVariables = Dictionary(
            uniqueKeysWithValues: externalVariables.lazy.map { ($1, $0.anyExternalVariable(mapsTo: $1)) }
        )
        let sensors = Dictionary(
            uniqueKeysWithValues: sensors.lazy.map { ($1, $0.anySensor(mapsTo: $1)) }
        )
        self.make = {
            wrappedValue.initial(actuators: actuators, externalVariables: externalVariables, sensors: sensors)
        }
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

}
