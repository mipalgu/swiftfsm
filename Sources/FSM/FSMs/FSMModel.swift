public protocol FSMModel<StateType>: ContextUser, EnvironmentUser {

    associatedtype Dependencies: DataStructure = EmptyDataStructure

    associatedtype Parameters: DataStructure = EmptyDataStructure

    associatedtype Result: DataStructure = EmptyDataStructure

    associatedtype Ringlet: RingletProtocol where
        Ringlet.StateType == StateType,
        Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment>, StateID>

    associatedtype StateType: TypeErasedState
        where StateType.FSMsContext == Context,
            StateType.Environment == Environment

    var initialState: KeyPath<Self, StateInformation> { get }

    var suspendState: KeyPath<Self, StateInformation>? { get }

}

public extension FSMModel {

    typealias Async<Result: DataStructure> = ASyncProperty<Result>

    typealias Sync<Result: DataStructure> = SyncProperty<Result>

    typealias SubMachine = SubMachineProperty

    typealias Actuator<Handler: ActuatorHandler> = ActuatorProperty<Environment, Handler>

    typealias ExternalVariable<Handler: ExternalVariableHandler> = ExternalVariableProperty<Environment, Handler>

    typealias GlobalVariable<Value: GlobalVariableValue>
        = GlobalVariableProperty<Environment, InMemoryGlobalVariable<Value>>

    typealias Sensor<Handler: SensorHandler> = SensorProperty<Environment, Handler>

    typealias State = StateProperty<StateType, Self>

    // swiftlint:disable:next identifier_name
    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition:
            @Sendable @escaping (StateContext<EmptyDataStructure, Context, Environment>) -> Bool
                = { _ in true }
    ) -> AnyTransition<
            StateContext<EmptyDataStructure, Context, Environment>,
            (Self) -> StateInformation
    > {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to state: String,
        canTransition:
            @Sendable @escaping (StateContext<EmptyDataStructure, Context, Environment>) -> Bool
                = { _ in true }
    ) -> AnyTransition<
        StateContext<EmptyDataStructure, Context, Environment>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: state, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to keyPath: KeyPath<Self, StateInformation>,
        context _: StatesContext.Type,
        canTransition:
            @Sendable @escaping (StateContext<StatesContext, Context, Environment>) -> Bool
                = { _ in true }
    ) -> AnyTransition<
        StateContext<StatesContext, Context, Environment>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to state: String,
        context _: StatesContext.Type,
        canTransition:
            @Sendable @escaping (StateContext<StatesContext, Context, Environment>) -> Bool
                = { _ in true }
    ) -> AnyTransition<
        StateContext<StatesContext, Context, Environment>,
        (Self) -> StateInformation
    > {
        AnyTransition(to: state, canTransition: canTransition)
    }

    var suspendState: KeyPath<Self, StateInformation>? { nil }

    func id(of keyPath: KeyPath<Self, StateInformation>) -> StateID {
        self[keyPath: keyPath].id
    }

    func id(of state: String) -> StateID {
        IDRegistrar.id(of: state)
    }

}
