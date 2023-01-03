@dynamicMemberLookup
public struct StateContext<
    StateContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
> {

    public var state: StateContext

    public var fsm: FSMsContext

    public var environment: Environment

    public var parameters: Parameters

    public var result: Result?

    var status: FSMStatus

    public var isFinished: Bool {
        status == .finished
    }

    public var isSuspended: Bool {
        if case .suspended = status {
            return true
        } else {
            return false
        }
    }

    public init(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.init(
            state: unsafeBitCast(fsmContext.state, to: StateContext.self),
            fsm: fsmContext.fsm,
            environment: fsmContext.environment,
            parameters: fsmContext.parameters,
            result: fsmContext.result,
            status: fsmContext.status
        )
    }

    public init(
        state: StateContext,
        fsm: FSMsContext,
        environment: Environment,
        parameters: Parameters,
        result: Result?
    ) {
        self.init(
            state: state,
            fsm: fsm,
            environment: environment,
            parameters: parameters,
            result: result,
            status: .executing(transitioned: true)
        )
    }

    init(
        state: StateContext,
        fsm: FSMsContext,
        environment: Environment,
        parameters: Parameters,
        result: Result?,
        status: FSMStatus
    ) {
        self.state = state
        self.fsm = fsm
        self.environment = environment
        self.parameters = parameters
        self.result = result
        self.status = status
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<StateContext, T>) -> T {
        state[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<StateContext, T>) -> T {
        get { state[keyPath: keyPath] }
        set { state[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<FSMsContext, T>) -> T {
        fsm[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { fsm[keyPath: keyPath] }
        set { fsm[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Environment, T>) -> T {
        environment[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { environment[keyPath: keyPath] }
        set { environment[keyPath: keyPath] = newValue }
    }

    public mutating func update(from fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        state = unsafeBitCast(fsmContext.state, to: StateContext.self)
        fsm = fsmContext.fsm
        environment = fsmContext.environment
        parameters = fsmContext.parameters
        result = fsmContext.result
        status = fsmContext.status
    }

    public mutating func restart() {
        status = .restarting
    }

    public mutating func resume() {
        status = .resuming
    }

    public mutating func suspend() {
        status = .suspending
    }

}
