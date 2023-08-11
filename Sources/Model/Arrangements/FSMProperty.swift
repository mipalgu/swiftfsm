import FSM

/// A convenience property wrapper that enables modelling a finite state machine
/// and it's dependencies.
@propertyWrapper
public struct FSMProperty<Arrangement: ArrangementProtocol> {

    /// Create the finite state machine.
    ///
    /// - Parameter: The arrangement containing the finite state machine.
    ///
    /// - Returns: A tuple containing the type-erased finite state machine as
    /// an `Exectuable`, and a function for creating the initial context for the
    /// finite state machine.
    public let make: (Arrangement) -> (Executable, ((any DataStructure)?) -> AnySchedulerContext)

    /// The metadata associated with the finite state machine.
    ///
    /// The metadata of a finite state machine contains information such as the
    /// finite state machines name, identifer, and the dependencies that the
    /// finite state machine has to other finite state machines.
    public let projectedValue: FSMInformation

    /// The actual model of the finite state machine that may be utilised to
    /// create the `FiniteStateMachine` that can be executed by a scheduler.
    public let wrappedValue: any FSM

    // swiftlint:disable line_length

    /// Create a new finite state machine property.
    ///
    /// This initialiser automatically computes the metadata of the finite state
    /// machine.
    ///
    /// - Parameter wrappedValue: The model of the finite state machine.
    public init<FSM: Model.FSM>(
        wrappedValue: FSM,
        actuators: (KeyPath<Arrangement, AnyArrangementActuator>, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        externalVariables: (KeyPath<Arrangement, AnyArrangementExternalVariable>, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        globalVariables: (KeyPath<Arrangement, AnyArrangementGlobalVariable>, mapsTo: PartialKeyPath<FSM.Environment>) ...,
        sensors: (KeyPath<Arrangement, AnyArrangementSensor>, mapsTo: PartialKeyPath<FSM.Environment>) ...
    ) {
        self.make = { arrangement in
            wrappedValue.initial(
                actuators: actuators.map {
                    arrangement[keyPath: $0].anyActuator(mapsTo: $1)
                },
                externalVariables: externalVariables.map {
                    arrangement[keyPath: $0].anyExternalVariable(mapsTo: $1)
                },
                globalVariables: globalVariables.map {
                    arrangement[keyPath: $0].anyGlobalVariable(mapsTo: $1)
                },
                sensors: sensors.map {
                    arrangement[keyPath: $0].anySensor(mapsTo: $1)
                }
            )
        }
        self.projectedValue = FSMInformation(fsm: wrappedValue)
        self.wrappedValue = wrappedValue
    }

    // swiftlint:enable line_length

}
