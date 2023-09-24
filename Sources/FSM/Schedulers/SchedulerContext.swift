@dynamicMemberLookup
public struct SchedulerContext<
    StateType: TypeErasedState,
    RingletsContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: SchedulerContextProtocol {

    public internal(set) var fsmID: Int

    public internal(set) var fsmName: String

    public var duration: Duration

    public internal(set) var transitioned: Bool

    public var startTime: ContinuousClock.Instant = .now

    public var data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>

    // swiftlint:disable:next implicitly_unwrapped_optional
    public internal(set) var states: UnsafePointer<
        FSMState<StateType, Parameters, Result, FSMsContext, Environment>
    >!

    public var ringletContext: RingletsContext {
        get {
            data.ringletContext
        }
        set {
            data.ringletContext = newValue
        }
    }

    public var fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result> {
        get {
            data.fsmContext
        }
        set {
            data.fsmContext = newValue
        }
    }

    public var fsm: FSMsContext {
        get {
            data.fsmContext.context
        }
        set {
            data.fsmContext.context = newValue
        }
    }

    public var environment: Environment {
        get {
            data.fsmContext.environment
        }
        set {
            data.fsmContext.environment = newValue
        }
    }

    public var parameters: Parameters {
        data.fsmContext.parameters
    }

    public var result: Result? {
        get {
            data.fsmContext.result
        }
        set {
            data.fsmContext.result = newValue
        }
    }

    public var status: FSMStatus {
        get {
            data.fsmContext.status
        }
        set {
            data.fsmContext.status = newValue
        }
    }

    public var initialState: StateID {
        data.initialState
    }

    public var currentState: StateID {
        data.currentState
    }

    public var previousState: StateID {
        data.previousState
    }

    public var suspendState: StateID {
        data.suspendState
    }

    public var suspendedState: StateID? {
        data.suspendedState
    }

    public init(
        fsmID: Int,
        fsmName: String,
        duration: Duration = .zero,
        transitioned: Bool = true,
        data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>,
        states: UnsafePointer<FSMState<StateType, Parameters, Result, FSMsContext, Environment>>? = nil
    ) {
        self.fsmID = fsmID
        self.fsmName = fsmName
        self.duration = duration
        self.transitioned = transitioned
        self.data = data
        self.states = states
    }

    public func after(_ duration: Duration) -> Bool {
        self.duration > duration
    }

    public func context(forState index: Int) -> AnyStateContext<FSMsContext, Environment, Parameters, Result>
    {
        data.stateContexts[index]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { data.fsmContext.context[keyPath: keyPath] }
        set { data.fsmContext.context[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { data.fsmContext.environment[keyPath: keyPath] }
        set { data.fsmContext.environment[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
        data.fsmContext.parameters[keyPath: keyPath]
    }

}
