/// Contains convenience utility functions that make creating an FSMModel
/// easier.
public extension FSMModel {

    /// A dependency to a parameterised machine that executes asynchronously.
    typealias Async<Result: DataStructure> = ASyncProperty<Result>

    /// A dependency to a write-only environment variable.
    typealias Actuator<Handler: ActuatorHandler> = ActuatorProperty<Environment, Handler>

    /// A dependency to an environment variable.
    typealias ExternalVariable<Handler: ExternalVariableHandler> = ExternalVariableProperty<Environment, Handler>

    /// A dependency to a variable shared by all fsms within an `Arrangement`.
    typealias GlobalVariable<Value: GlobalVariableValue>
        = GlobalVariableProperty<Environment, InMemoryGlobalVariable<Value>>

    /// A dependency to a parameterised machine that executes asynchronously but
    /// is also capable of deliverying results before it completes executing.
    typealias Partial<Result: DataStructure, Partial: DataStructure> = PartialProperty<Result, Partial>

    /// A dependency to a read-only environment variable.
    typealias Sensor<Handler: SensorHandler> = SensorProperty<Environment, Handler>

    /// A state contained within this machine.
    typealias State = StateProperty<StateType, Self>

    /// A dependency to another machine that this machine may control.
    typealias SubMachine = SubMachineProperty

    /// A dependency to a parameterised machine that executes synchronously.
    typealias Sync<Result: DataStructure> = SyncProperty<Result>

    // swiftlint:disable identifier_name

    /// Create a transition between two states.
    /// 
    /// - Parameter keyPath: A path to the target state of the transition.
    /// 
    /// - Parameter canTransition: A function that takes the source states
    /// context and returns a boolean value indicating whether the transition
    /// is valid or not.
    /// 
    /// - Returns: The newly created transition.
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

    /// Create a transition between two states.
    /// 
    /// - Parameter state: The name of the taget state of the transition.
    /// 
    /// - Parameter canTransition: A function that takes the source states
    /// context and returns a boolean value indicating whether the transition
    /// is valid or not.
    /// 
    /// - Returns: The newly created transition.
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

    /// Create a transition between two states.
    /// 
    /// - Parameter keyPath: A path to the target state of the transition.
    /// 
    /// - Parameter context: The type of the source states context.
    /// 
    /// - Parameter canTransition: A function that takes the source states
    /// context and returns a boolean value indicating whether the transition
    /// is valid or not.
    /// 
    /// - Returns: The newly created transition.
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

    /// Create a transition between two states.
    /// 
    /// - Parameter state: The name of the taget state of the transition.
    /// 
    /// - Parameter context: The type of the source states context.
    /// 
    /// - Parameter canTransition: A function that takes the source states
    /// context and returns a boolean value indicating whether the transition
    /// is valid or not.
    /// 
    /// - Returns: The newly created transition.
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

    // swiftlint:enable identifier_name

}
