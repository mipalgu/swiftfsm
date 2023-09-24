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

    private let model: Model

    private let stateIDs: [String: StateID]

    private let stateNames: [StateID: String]

    public var context: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>

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
        fsm.states[context.data.initialState]
    }

    public var isFinished: Bool {
        let erased = context as SchedulerContextProtocol
        return withUnsafePointer(to: erased) {
            fsm.isFinished(context: $0)
        }
    }

    public var isSuspended: Bool {
        let erased = context as SchedulerContextProtocol
        return withUnsafePointer(to: erased) {
            fsm.isSuspended(context: $0)
        }
    }

    public var currentState: FSMState<StateType, Parameters, Result, Context, Environment> {
        get {
            fsm.states[context.data.currentState]
        } set {
            context.data.currentState = newValue.id
        }
    }

    public var previousState: FSMState<StateType, Parameters, Result, Context, Environment> {
        get {
            fsm.states[context.data.previousState]
        } set {
            context.data.previousState = newValue.id
        }
    }

    public var suspendState: FSMState<StateType, Parameters, Result, Context, Environment> {
        fsm.states[context.data.suspendState]
    }

    public var suspendedState: FSMState<StateType, Parameters, Result, Context, Environment>? {
        get {
            context.data.suspendedState.map { fsm.states[$0] }
        } set {
            context.data.suspendedState = newValue?.id
        }
    }

    public init(
        model: Model,
        actuators: [(PartialKeyPath<Environment>, AnyActuatorHandler<Environment>)] = [],
        externalVariables: [(PartialKeyPath<Environment>, AnyExternalVariableHandler<Environment>)] = [],
        globalVariables: [(PartialKeyPath<Environment>, AnyGlobalVariableHandler<Environment>)] = [],
        sensors: [(PartialKeyPath<Environment>, AnySensorHandler<Environment>)] = []
    ) {
        let data = model.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        let typedFSM = data.executable as! FiniteStateMachine<
            StateType,
            Ringlet,
            Parameters,
            Result,
            Context,
            Environment
        >
        self.model = model
        var stateIDs: [String: Int] = [:]
        var stateNames: [Int: String] = [:]
        stateIDs.reserveCapacity(typedFSM.statesCount)
        stateNames.reserveCapacity(typedFSM.statesCount)
        for index in 0..<typedFSM.statesCount {
            stateIDs[typedFSM.states[index].name] = typedFSM.states[index].id
            stateNames[typedFSM.states[index].id] = typedFSM.states[index].name
        }
        self.stateIDs = stateIDs
        self.stateNames = stateNames
        // swiftlint:disable force_cast
        let contextPtr = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { contextPtr.deallocate() }
        data.initialiseContext(parameters: EmptyDataStructure(), context: contextPtr)
        self.context = contextPtr.pointee as! SchedulerContext<
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
        var erased = context as SchedulerContextProtocol
        withUnsafeMutablePointer(to: &erased) {
            fsm.next(context: $0)
        }
        context = erased as! SchedulerContext<
            StateType,
            Ringlet.Context,
            Context,
            Environment,
            Parameters,
            Result
        >
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
        var erased = context as SchedulerContextProtocol
        withUnsafeMutablePointer(to: &erased) {
            fsm.saveSnapshot(context: $0)
        }
        context = erased as! SchedulerContext<
            StateType,
            Ringlet.Context,
            Context,
            Environment,
            Parameters,
            Result
        >
    }

    public func state(
        for keyPath: KeyPath<Model, StateInformation>
    ) -> FSMState<StateType, Parameters, Result, Context, Environment> {
        let information = model[keyPath: keyPath]
        guard let id = stateIDs[information.name] else {
            fatalError("State does not exist within finite state machine.")
        }
        return fsm.states[id]
    }

    public func takeSnapshot() {
        var erased = context as SchedulerContextProtocol
        withUnsafeMutablePointer(to: &erased) {
            fsm.takeSnapshot(context: $0)
        }
        context = erased as! SchedulerContext<
            StateType,
            Ringlet.Context,
            Context,
            Environment,
            Parameters,
            Result
        >
    }

}
