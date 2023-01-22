public protocol FSMModel: FSMProtocol {

    associatedtype Dependencies: DataStructure, EmptyInitialisable = EmptyDataStructure

    var name: String { get }

    var initialState: KeyPath<Self, StateInformation> { get }

    var suspendState: KeyPath<Self, StateInformation>? { get }

}

public extension FSMModel {

    typealias Async<Result: DataStructure> = ASyncProperty<Result>

    typealias Actuator<Handler: ActuatorHandler> = ActuatorProperty<Environment, Handler>

    typealias ExternalVariable<Handler: ExternalVariableHandler> = ExternalVariableProperty<Environment, Handler>

    typealias GlobalVariable<Value: GlobalVariableValue>
        = GlobalVariableProperty<Environment, InMemoryGlobalVariable<Value>>

    typealias Partial<Result: DataStructure, Partial: DataStructure> = PartialProperty<Result, Partial>

    typealias Sensor<Handler: SensorHandler> = SensorProperty<Environment, Handler>

    typealias State = StateProperty<StateType, Self>

    typealias SubMachine = SubMachineProperty

    typealias Sync<Result: DataStructure> = SyncProperty<Result>

    // swiftlint:disable:next identifier_name
    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition:
            @Sendable @escaping (StateContext<
                EmptyDataStructure,
                Context,
                Environment,
                Parameters,
                Result
            >) -> Bool = { _ in true }
    ) -> AnyTransition<
            StateContext<EmptyDataStructure, Context, Environment, Parameters, Result>,
            (Self) -> StateInformation
    > {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to state: String,
        canTransition:
            @Sendable @escaping (StateContext<
                EmptyDataStructure,
                Context,
                Environment,
                Parameters,
                Result
            >) -> Bool = { _ in true }
    ) -> AnyTransition<
        StateContext<EmptyDataStructure, Context, Environment, Parameters, Result>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: state, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to keyPath: KeyPath<Self, StateInformation>,
        context _: StatesContext.Type,
        canTransition:
            @Sendable @escaping (StateContext<
                StatesContext,
                Context,
                Environment,
                Parameters,
                Result
            >) -> Bool = { _ in true }
    ) -> AnyTransition<
        StateContext<StatesContext, Context, Environment, Parameters, Result>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to state: String,
        context _: StatesContext.Type,
        canTransition:
            @Sendable @escaping (StateContext<
                StatesContext,
                Context,
                Environment,
                Parameters,
                Result
            >) -> Bool = { _ in true }
    ) -> AnyTransition<
        StateContext<StatesContext, Context, Environment, Parameters, Result>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: state, canTransition: canTransition)
    }

    var dependencies: [FSMDependency] {
        let deps = Self.Dependencies()
        let mirror = Mirror(reflecting: deps)
        return mirror.children.compactMap {
            ($0.value as? DependencyCalculatable)?.dependency
        }
    }

    var suspendState: KeyPath<Self, StateInformation>? { nil }

    func id(of keyPath: KeyPath<Self, StateInformation>) -> StateID {
        self[keyPath: keyPath].id
    }

    func id(of state: String) -> StateID {
        IDRegistrar.id(of: state)
    }

}

public extension FSMModel {

    func fsm(with parameters: Parameters) -> FiniteStateMachine<
        StateType,
        Ringlet,
        Parameters,
        Result,
        Context,
        Environment
    > {
        var newIds: [StateID: Int] = [:]
        var latestID = 0
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
            states.append(FSMState(
                id: newID,
                name: name,
                environmentVariables: [],
                stateType: stateType,
                transitions: transitions.map { AnyTransition(to: $0) }
            ))
            return newID
        }
        let modelInitialState = id(for: self[keyPath: self.initialState].id)
        let initialState = newState(named: "__Initial", transitions: [modelInitialState])
        let previousState = newState(named: "__Previous")
        let suspendState: Int
        if let suspendStatePath = self.suspendState {
            suspendState = id(for: self[keyPath: suspendStatePath].id)
        } else {
            suspendState = newState(named: "__Suspend")
        }
        var actuatorsArr = Array(self.actuators)
        var externalVariablesArr = Array(self.externalVariables)
        var sensorsArr = Array(self.sensors)
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

    var name: String {
        guard let name = "\(type(of: self))".split(separator: ".").first.map(String.init) else {
            // swiftlint:disable:next line_length
            fatalError("Unable to compute name of FSM with type \(type(of: self)). Please specify a name: let name = \"<MyName>\"")
        }
        return name
    }

    private var anyStates: [Int: AnyStateProperty] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let state = $0.value as? AnyStateProperty else {
                return nil
            }
            return (state.information.id, state)
        })
    }

    private var states: [Int: StateType] {
        anyStates.mapValues {
            guard let state = $0 as? StateType else {
                fatalError("Unable to cast state to it's corresponding StateType.")
            }
            return state
        }
    }

    private func stateContexts(fsmContext: FSMContext<Context, Environment, Parameters, Result>)
        -> [Int: AnyStateContext<Context, Environment, Parameters, Result>] {
        states.mapValues { $0.initialContext(fsmContext: fsmContext) }
    }

    private var transitions: [
        Int: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]
    ] {
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

    private var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let actuator = $0.value as? AnyActuatorProperty else {
                return nil
            }
            guard let mapPath = actuator.erasedMapPath as? PartialKeyPath<Environment> else {
                fatalError("Unable to cast erasedMapPath to PartialKeyPath<Environment>.")
            }
            guard let typeErased = actuator.typeErased as? AnyActuatorHandler<Environment> else {
                fatalError("Unable to create AnyActuatorHandler<Environment> from AnyActuatorProperty.")
            }
            return (mapPath, typeErased)
        })
    }

    private var actuatorInitialValues: [PartialKeyPath<Environment>: Sendable] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let actuator = $0.value as? AnyActuatorProperty else {
                return nil
            }
            guard let mapPath = actuator.erasedMapPath as? PartialKeyPath<Environment> else {
                fatalError("Unable to cast erasedMapPath to PartialKeyPath<Environment>.")
            }
            return (mapPath, actuator.erasedInitialValue)
        })
    }

    private var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let externalVariable = $0.value as? AnyExternalVariableProperty else {
                return nil
            }
            guard let mapPath = externalVariable.erasedMapPath as? PartialKeyPath<Environment> else {
                fatalError("Unable to cast erasedMapPath to PartialKeyPath<Environment>.")
            }
            guard let typeErased = externalVariable.typeErased as? AnyExternalVariableHandler<Environment> else {
                fatalError(
                    "Unable to create AnyExternalVariableHandler<Environment> from AnyExternalVariableProperty."
                )
            }
            return (mapPath, typeErased)
        })
    }

    private var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let actuator = $0.value as? AnySensorProperty else {
                return nil
            }
            guard let mapPath = actuator.erasedMapPath as? PartialKeyPath<Environment> else {
                fatalError("Unable to cast erasedMapPath to PartialKeyPath<Environment>.")
            }
            guard let typeErased = actuator.typeErased as? AnySensorHandler<Environment> else {
                fatalError("Unable to create AnySensorHandler<Environment> from AnySensorProperty.")
            }
            return (mapPath, typeErased)
        })
    }

}
