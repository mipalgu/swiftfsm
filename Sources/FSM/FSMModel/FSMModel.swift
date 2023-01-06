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

    var environmentVariables: Set<PartialKeyPath<Self.Environment>> {
        Set(anyStates.values.flatMap {
            guard
                let environmentVariables = $0.erasedEnvironmentVariables as? Set<PartialKeyPath<Environment>>
            else {
                fatalError("Unable to cast erasedEnvironmentVariables to Set<PartialKeyPath<Environment>>")
            }
            return Array(environmentVariables)
        })
    }

    func initialContext(parameters: Parameters) -> FSMContext<Context, Environment, Parameters, Result> {
        let initialStateInfo = self[keyPath: initialState]
        guard let stateContext = stateContexts[initialStateInfo.id] else {
            fatalError("Unable to fetch initial state.")
        }
        return FSMContext(
            state: stateContext,
            fsm: Context(),
            environment: Environment(),
            parameters: parameters,
            result: nil
        )
    }

    var initialRinglet: Ringlet {
        Ringlet()
    }

    var name: String {
        guard let name = "\(type(of: self))".split(separator: ".").first.map(String.init) else {
            // swiftlint:disable:next line_length
            fatalError("Unable to compute name of FSM with type \(type(of: self)). Please specify a name: let name = \"<MyName>\"")
        }
        return name
    }

    func fsm(parameters: (any DataStructure)?) -> (
        FiniteStateMachine<StateType, Ringlet, Parameters, Result, Context, Environment>,
        RingletContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
    ) {
        if let params = parameters as? Parameters {
            return FiniteStateMachine.initial(from: self, with: params)
        } else if
            let type = Parameters.self as? EmptyInitialisable.Type,
            let params = type.init() as? Parameters
        {
            return FiniteStateMachine.initial(from: self, with: params)
        } else {
            fatalError("Missing parameters for \(name).")
        }
    }

    var anyStates: [Int: AnyStateProperty] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let state = $0.value as? AnyStateProperty else {
                return nil
            }
            return (state.information.id, state)
        })
    }

    var states: [Int: StateType] {
        anyStates.mapValues {
            guard let state = $0 as? StateType else {
                fatalError("Unable to cast state to it's corresponding StateType.")
            }
            return state
        }
    }

    var stateContexts: [Int: Sendable] {
        let mirror = Mirror(reflecting: self)
        return Dictionary(uniqueKeysWithValues: mirror.children.compactMap {
            guard let state = $0.value as? AnyStateProperty else {
                return nil
            }
            return (state.information.id, state.context)
        })
    }

    var transitions: [Int: [AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID>]] {
        anyStates.mapValues {
            guard
                let transitions = $0.erasedTransitions(for: self)
                    as? [AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID>]
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

    var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>] {
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

    var actuatorInitialValues: [PartialKeyPath<Environment>: Sendable] {
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

    var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>] {
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

    var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>] {
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
