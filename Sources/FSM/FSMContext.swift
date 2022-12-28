@dynamicMemberLookup
public struct FSMContext<Context: DataStructure, Environment: DataStructure>: FiniteStateMachineOperations {

    public var state: Sendable

    public var fsm: Context

    public var environment: Environment

    public var status: FSMStatus

    public var isFinished: Bool {
        status == .finished
    }

    public var isSuspended: Bool {
        status == .suspended
    }

    public init<StatesContext: DataStructure>(
        stateContext: StateContext<StatesContext, Context, Environment>
    ) {
        self.init(
            state: stateContext.state as Sendable,
            fsm: stateContext.fsm,
            environment: stateContext.environment
        )
    }

    public init(state: Sendable, fsm: Context, environment: Environment, status: FSMStatus = .executing) {
        self.state = state
        self.fsm = fsm
        self.environment = environment
        self.status = status
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Context, T>) -> T {
        fsm[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Context, T>) -> T {
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

    public mutating func update<StatesContext: DataStructure>(
        from stateContext: StateContext<StatesContext, Context, Environment>
    ) {
        self.state = stateContext.state as Sendable
        self.fsm = stateContext.fsm
        self.environment = stateContext.environment
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
