import FSM
import Model

public final class FSMTester<Model: FSM> where
    Model.StateType.FSMsContext == Model.Context,
    Model.StateType.Environment == Model.Environment,
    Model.Ringlet.StateType == Model.StateType,
    Model.Ringlet.TransitionType == AnyTransition<
        AnyStateContext<Model.Context, Model.Environment, Model.Parameters, Model.Result>,
        StateID
    >
{

    public typealias StateType = Model.StateType
    public typealias Ringlet = Model.Ringlet
    public typealias Parameters = Model.Parameters
    public typealias Result = Model.Result
    public typealias Context = Model.Context
    public typealias Environment = Model.Environment

    public enum NextResult: Hashable, Codable, Sendable {

        /// Represents the normal operation of the Finite State Machine.
        ///
        /// The Finite State Machine is not suspended and is not in an accepting
        /// state.
        case executing(transitioned: FSMStatus.TransitionType)

        /// Represents a Finite State Machine that is in an accepting state and
        /// has executed that accepting state at least once.
        case finished

        /// Represents a Finite State Machine that has transitioned back to the
        /// initial state.
        case restarted(transitioned: FSMStatus.TransitionType)

        /// Represents a Finite State Machine that has just been resumed and is
        /// ready to execute the previously suspended state.
        case resumed(transitioned: FSMStatus.TransitionType)

        /// Represents a Finite State Machine that is suspended and should execute
        /// the suspend state.
        case suspended(transitioned: FSMStatus.TransitionType)

        public var didTransition: Bool {
            switch self {
            case .finished:
                return false
            case .executing(let transitioned), .restarted(let transitioned),
                .resumed(let transitioned), .suspended(let transitioned):
                return transitioned.transitioned
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
                self = .restarted(
                    transitioned: context.previousState == context.currentState ? .noTransition : .newState
                )
            case .resumed(let transitioned):
                self = .resumed(transitioned: transitioned)
            case .resuming:
                self = .resumed(
                    transitioned: context.previousState == context.currentState ? .noTransition : .newState
                )
            case .suspended(let transitioned):
                self = .suspended(transitioned: transitioned)
            case .suspending:
                self = .suspended(
                    transitioned: context.previousState == context.currentState ? .noTransition : .newState
                )
            }
        }

    }

    private let model: Model

    private let stateIDs: [String: StateID]

    private let stateNames: [StateID: String]

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

    public var duration: Duration {
        get {
            context.duration
        } set {
            context.duration = newValue
        }
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

    public init(
        model: Model,
        actuators: [(PartialKeyPath<Environment>, AnyActuatorHandler)] = [],
        externalVariables: [(PartialKeyPath<Environment>, AnyExternalVariableHandler)] = [],
        globalVariables: [(PartialKeyPath<Environment>, AnyGlobalVariableHandler)] = [],
        sensors: [(PartialKeyPath<Environment>, AnySensorHandler)] = []
    ) {
        let (fsm, contextFactory) = model.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        let typedFSM = fsm as! FiniteStateMachine<
            StateType,
            Ringlet,
            Parameters,
            Result,
            Context,
            Environment
        >
        self.model = model
        self.stateIDs = Dictionary(uniqueKeysWithValues: typedFSM.stateContainer.states.map {
            ($0.name, $0.id)
        })
        self.stateNames = Dictionary(uniqueKeysWithValues: typedFSM.stateContainer.states.map {
            ($0.id, $0.name)
        })
        // swiftlint:disable force_cast
        self.context = contextFactory(EmptyDataStructure()) as! SchedulerContext<
            StateType,
            Ringlet.Context,
            Context,
            Environment,
            Parameters,
            Result
        >
        self.fsm = typedFSM
        // swiftlint:enable force_cast
    }

    @discardableResult
    public func next() -> NextResult {
        fsm.next(context: context)
        return NextResult(status: context.data.fsmContext.status, context: context)
    }

    @discardableResult
    public func ringlet() -> NextResult {
        takeSnapshot()
        let result = next()
        saveSnapshot()
        return result
    }

    public func saveSnapshot() {
        fsm.saveSnapshot(context: context)
    }

    public func state(
        for keyPath: KeyPath<Model, StateInformation>
    ) -> FSMState<StateType, Parameters, Result, Context, Environment> {
        let information = model[keyPath: keyPath]
        guard let id = stateIDs[information.name] else {
            fatalError("State does not exist within finite state machine.")
        }
        return fsm.stateContainer.states[id]
    }

    public func takeSnapshot() {
        fsm.takeSnapshot(context: context)
    }

}
