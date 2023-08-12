@testable import FSM
import Model

public struct FSMTester<
    StateType: TypeErasedState,
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> where
    StateType.FSMsContext == Context,
    StateType.Environment == Environment,
    Ringlet.StateType == StateType,
    Ringlet.TransitionType == AnyTransition<
        AnyStateContext<Context, Environment, Parameters, Result>,
        StateID
    >
{

    public enum NextResult: Hashable, Codable, Sendable {

        /// Represents the normal operation of the Finite State Machine.
        ///
        /// The Finite State Machine is not suspended and is not in an accepting
        /// state.
        case executing(transitioned: Bool)

        /// Represents a Finite State Machine that is in an accepting state and
        /// has executed that accepting state at least once.
        case finished

        /// Represents a Finite State Machine that has transitioned back to the
        /// initial state.
        case restarted(transitioned: Bool)

        /// Represents a Finite State Machine that has just been resumed and is
        /// ready to execute the previously suspended state.
        case resumed(transitioned: Bool)

        /// Represents a Finite State Machine that is suspended and should execute
        /// the suspend state.
        case suspended(transitioned: Bool)

        public var didTransition: Bool {
            switch self {
            case .finished:
                return false
            case .executing(let transitioned), .restarted(let transitioned),
                .resumed(let transitioned), .suspended(let transitioned):
                return transitioned
            }
        }

        public init(
            status: FSMStatus,
            context: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        ) {
            switch status {
            case .executing(let transitioned):
                self = .executing(transitioned: transitioned)
            case .finished:
                self = .finished
            case .restarted(let transitioned):
                self = .restarted(transitioned: transitioned)
            case .restarting:
                self = .restarted(transitioned: context.transitioned)
            case .resumed(let transitioned):
                self = .resumed(transitioned: transitioned)
            case .resuming:
                self = .resumed(transitioned: context.transitioned)
            case .suspended(let transitioned):
                self = .suspended(transitioned: transitioned)
            case .suspending:
                self = .suspended(transitioned: context.transitioned)
            }
        }

    }

    public let context: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>

    public let fsm: FiniteStateMachine<
        StateType,
        Ringlet,
        Parameters,
        Result,
        Context,
        Environment
    >

    public var didTransition: Bool {
        context.transitioned
    }

    public var initialState: FSMState<StateType, Parameters, Result, Context, Environment> {
        fsm.stateContainer.states[context.data.initialState]
    }

    public var isFinished: Bool {
        fsm.isFinished(context: context)
    }

    public var isSuspended: Bool {
        fsm.isSuspended(context: context)
    }

    public var currentState: FSMState<StateType, Parameters, Result, Context, Environment> {
        get {
            fsm.stateContainer.states[context.data.currentState]
        } set {
            context.data.currentState = newValue.id
        }
    }

    public var previousState: FSMState<StateType, Parameters, Result, Context, Environment> {
        get {
            fsm.stateContainer.states[context.data.previousState]
        } set {
            context.data.previousState = newValue.id
        }
    }

    public var suspendState: FSMState<StateType, Parameters, Result, Context, Environment> {
        fsm.stateContainer.states[context.data.suspendState]
    }

    public var suspendedState: FSMState<StateType, Parameters, Result, Context, Environment>? {
        get {
            context.data.suspendedState.map { fsm.stateContainer.states[$0] }
        } set {
            context.data.suspendedState = newValue?.id
        }
    }

    public init<Model: FSM>(
        model: Model,
        actuators: [(PartialKeyPath<Environment>, AnyActuatorHandler<Environment>)],
        externalVariables: [(PartialKeyPath<Environment>, AnyExternalVariableHandler<Environment>)],
        globalVariables: [(PartialKeyPath<Environment>, AnyGlobalVariableHandler<Environment>)],
        sensors: [(PartialKeyPath<Environment>, AnySensorHandler<Environment>)]
    ) where
        Model.StateType == StateType,
        Model.Ringlet == Ringlet,
        Model.Parameters == Parameters,
        Model.Result == Result,
        Model.Context == Context,
        Model.Environment == Environment
    {
        let (fsm, contextFactory) = model.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        // swiftlint:disable force_cast
        self.context = contextFactory(EmptyDataStructure()) as! SchedulerContext<
            StateType,
            Ringlet.Context,
            Context,
            Environment,
            Parameters,
            Result
        >
        self.fsm = fsm as! FiniteStateMachine<
            StateType,
            Ringlet,
            Parameters,
            Result,
            Context,
            Environment
        >
        // swiftlint:enable force_cast
    }

    @discardableResult
    public func next() -> NextResult {
        fsm.next(context: context)
        return NextResult(status: context.data.fsmContext.status, context: context)
    }

    public func saveSnapshot() {
        fsm.saveSnapshot(context: context)
    }

    public func takeSnapshot() {
        fsm.takeSnapshot(context: context)
    }

}
