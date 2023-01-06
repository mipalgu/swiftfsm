@dynamicMemberLookup
public final class FSMContext<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: FiniteStateMachineOperations {

    var state: Sendable

    public var fsm: FSMsContext

    public var environment: Environment

    public var parameters: Parameters

    public var result: Result?

    public var status: FSMStatus

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

    public convenience init<StatesContext: DataStructure>(
        stateContext: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self.init(
            state: stateContext.state as Sendable,
            fsm: stateContext.fsm,
            environment: stateContext.environment,
            parameters: stateContext.parameters,
            result: stateContext.result,
            status: stateContext.status
        )
    }

    public convenience init(
        state: Sendable,
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
        state: Sendable,
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

    public subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
        parameters[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Parameters, T>) -> T {
        get { parameters[keyPath: keyPath] }
        set { parameters[keyPath: keyPath] = newValue }
    }

    public func restart() {
        status = .restarting
    }

    public func resume() {
        status = .resuming
    }

    public func suspend() {
        status = .suspending
    }

    public func update<StatesContext: DataStructure>(
        from stateContext: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        state = stateContext.state as Sendable
        fsm = stateContext.fsm
        environment = stateContext.environment
        parameters = stateContext.parameters
        result = stateContext.result
        status = stateContext.status
    }

}
