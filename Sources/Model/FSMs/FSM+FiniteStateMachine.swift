import FSM

/// Contains functionality that enables converting this FSM to a
/// `FiniteStateMachine` that can be executed within a schedule.
extension FSM {

    /// Fetch all dependencies as declared within this model.
    public var dependencies: [FSMDependency] {
        let deps = Self.Dependencies()
        let mirror = Mirror(reflecting: deps)
        return mirror.children.compactMap {
            ($0.value as? DependencyCalculatable)?.dependency
        }
    }

    /// Fetches all states and metadata associated with each state within this
    /// model as a dictionary where the key represents the id of the state and
    /// the value represents a type-erased @State property wrapper value.
    private var anyStates: [Int: AnyStateProperty] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(
            uniqueKeysWithValues: mirror.children.compactMap {
                guard let state = $0.value as? AnyStateProperty else {
                    return nil
                }
                return (state.information.id, state)
            }
        )
    }

    /// Fetches all states within this model as a dictionary where the key
    /// represents the id of the state and the value is the state that contains
    /// the execution logic.
    ///
    /// - Note: The states returned by this property only contain the execution
    /// logic, but do not contain any data or contexts associated with the
    /// state.
    private var states: [Int: StateType] {
        anyStates.mapValues {
            guard let state = $0 as? StateProperty<StateType, Self> else {
                fatalError("Unable to cast state to it's corresponding StateType.")
            }
            return state.wrappedValue
        }
    }

    /// Fetches all transitions within this model as a dictionary where the key
    /// represents the id of the source state, and the value represents the
    /// array of transitions that can be evaluated for that source state.
    private var transitions:
        [Int: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]]
    {
        anyStates.mapValues {
            guard
                let transitions = $0.erasedTransitions(for: self)
                    as? [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]
            else {
                // swiftlint:disable line_length
                fatalError(
                    "Unable to cast transition to [AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID>]"
                )
                // swiftlint:enable line_length
            }
            return transitions
        }
    }

    /// Create the corresponding `FiniteStateMachine` of this model represented
    /// as a type-erased `Executable`, and a factory function that takes a
    /// type-erased data structure that can be cast to `Self.Parameters` and
    /// returns a newly created `AnySchedulerContext`.
    ///
    /// - Attention: The id's associated with all states, transitions, and
    /// shared variables will be changed within the newly created data
    /// structures returned by this computed property. This is done to optimise
    /// lookup times. However, this means that you should not rely on the
    /// id's as accessed within this model.
    public func initial(
        actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>],
        externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>],
        sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]
    ) -> (Executable, ((any DataStructure)?) -> AnySchedulerContext) {
        let fsm = self.fsm(actuators: actuators, externalVariables: externalVariables, sensors: sensors)
        let factory: ((any DataStructure)?) -> AnySchedulerContext = {
            let data: FSMData<Ringlet.Context, Parameters, Result, Context, Environment>
            if let params = $0 as? Parameters {
                data = fsm.initialData(with: params)
            } else if let type = Parameters.self as? EmptyInitialisable.Type,
                let params = type.init() as? Parameters
            {
                data = fsm.initialData(with: params)
            } else {
                fatalError("Missing parameters for \(name).")
            }
            let context = SchedulerContext(
                fsmID: -1,
                data: data,
                stateContainer: StateContainer<StateType, Parameters, Result, Context, Environment>?.none
            )
            return context
        }
        return (fsm, factory)
    }

    /// Create the equivalent `FiniteStateMachine` for this model.
    ///
    /// This getter replaces all id's of all states, transitions, and shared
    /// variables so that the `FiniteStateMachine` may access them internally
    /// utilising a static array. This creates optimal O(1) lookup times but
    /// means that you should not rely on the existing id's of these properties
    /// as accessed from this model.
    private func fsm(
        actuators: [PartialKeyPath<Environment> : AnyActuatorHandler<Environment>],
        externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>],
        sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]
    ) -> FiniteStateMachine<StateType, Ringlet, Parameters, Result, Context, Environment> {
        var newIds: [StateID: Int] = [:]
        var latestID = 0
        /// Calculate a new id for a given state with an old ID.
        ///
        /// This ensures that there are no gaps between the id's of the states
        /// so that the id's can match the indexes of the states within a single
        /// array.
        ///
        /// - Parameter state: The original id of the state.
        ///
        /// - Returns: The new id, representing an index where to store the
        /// state in a new array that will be created.
        func id(for state: StateID) -> Int {
            if let id = newIds[state] {
                return id
            }
            let id = latestID
            latestID += 1
            newIds[state] = id
            return id
        }
        let anyStates = anyStates
        let stateTypes = states
        let transitions = transitions
        /// Convert the anyStates into an array of states where the id's of the
        /// states match the index of the state within this array.
        var states = anyStates.map {
            let oldID = $1.information.id
            let newID = id(for: $1.information.id)
            let name = $1.information.name
            guard
                let environmentVariables = $1.erasedEnvironmentVariables
                    as? [PartialKeyPath<Environment>]
            else {
                fatalError("Unable to cast environment variables for state \(name).")
            }
            guard let stateType = stateTypes[oldID] else {
                fatalError("Unable to fetch state type for state \(name).")
            }
            guard let transitions = transitions[oldID] else {
                fatalError("Unable to fetch transitions for state \(name).")
            }
            let newTransitions = transitions.map {
                $0.map { id(for: $0) }
            }
            return FSMState(
                id: newID,
                name: name,
                environmentVariables: Set(environmentVariables),
                stateType: stateType,
                transitions: newTransitions
            )
        }
        /// Create a new empty state that always transitions to particular
        /// targets and add it to states.
        ///
        /// - Parameter name: The unique name of the new state.
        ///
        /// - Parameter transitions: The targets that this state transitions to.
        ///
        /// - Returns: The index of the new state within the states array.
        func newState(named name: String, transitions: [Int] = []) -> Int {
            let oldID = IDRegistrar.id(of: name)
            guard anyStates[oldID] == nil else {
                fatalError("The \(name) state name is reserved. Please rename your state.")
            }
            let newID = id(for: oldID)
            guard newID == states.count else {
                fatalError("Calculated invalid id (\(newID)) for new state.")
            }
            let stateType = StateType.emptyState
            states.append(
                FSMState(
                    id: newID,
                    name: name,
                    environmentVariables: [],
                    stateType: stateType,
                    transitions: transitions.map { AnyTransition(to: $0) }
                )
            )
            return newID
        }
        // Create an initial pseudo state.
        let modelInitialState = id(for: self[keyPath: self.initialState].id)
        let initialState = newState(named: "__Initial", transitions: [modelInitialState])
        // Create an empty previous state so that the previous state and current state do not equal.
        let previousState = newState(named: "__Previous")
        // Create an empty suspend state if the model does not specify a suspend state.
        let suspendState: Int
        if let suspendStatePath = self.suspendState {
            suspendState = id(for: self[keyPath: suspendStatePath].id)
        } else {
            suspendState = newState(named: "__Suspend")
        }
        // Ensure that each state's identifier matches the state's index within the states array.
        states.sort { $0.id < $1.id }
        // Do a sanity check to ensure that we do not have states with duplicate id's.
        guard Set(states.map(\.id)).count == states.count else {
            fatalError("The states array contains states with duplicate ids: \(states)")
        }
        // Setup arrays of environment variables with new identifiers that represent the indexes within these
        // arrays.
        var actuatorsArr = Array(actuators)
        var externalVariablesArr = Array(externalVariables)
        var sensorsArr = Array(sensors)
        for index in actuatorsArr.indices {
            actuatorsArr[index].value.index = index
        }
        for index in externalVariablesArr.indices {
            externalVariablesArr[index].value.index = index
        }
        for index in sensorsArr.indices {
            sensorsArr[index].value.index = index
        }
        let actuators = Dictionary(uniqueKeysWithValues: actuatorsArr)
        let externalVariables = Dictionary(uniqueKeysWithValues: externalVariablesArr)
        let sensors = Dictionary(uniqueKeysWithValues: sensorsArr)
        let handlers = FSMHandlers(
            actuators: actuators,
            externalVariables: externalVariables,
            sensors: sensors
        )
        return FiniteStateMachine(
            stateContainer: StateContainer(states: states),
            ringlet: Ringlet(),
            handlers: handlers,
            initialState: initialState,
            initialPreviousState: previousState,
            suspendState: suspendState
        )
    }

}
