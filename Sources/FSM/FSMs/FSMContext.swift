@dynamicMemberLookup
public struct FSMContext<
    FSMsContext: DataStructure,
    Environment: EnvironmentSnapshot
>: FiniteStateMachineOperations {

    var state: Sendable

    public var fsm: FSMsContext

    public var environment: Snapshot<Environment>

    public var status: FSMStatus

    public var isFinished: Bool {
        status == .finished
    }

    public var isSuspended: Bool {
        status == .suspended
    }

    public init<StatesContext: DataStructure>(
        stateContext: StateContext<StatesContext, FSMsContext, Environment>
    ) {
        self.init(
            state: stateContext.state as Sendable,
            fsm: stateContext.fsm,
            environment: stateContext.environment
        )
    }

    public init(
        state: Sendable,
        fsm: FSMsContext,
        environment: Snapshot<Environment>,
        status: FSMStatus = .executing
    ) {
        self.state = state
        self.fsm = fsm
        self.environment = environment
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
        environment.get(keyPath)
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { environment.get(keyPath) }
        set { environment.set(keyPath, newValue) }
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

    public mutating func update<StatesContext: DataStructure>(
        from stateContext: StateContext<StatesContext, FSMsContext, Environment>
    ) {
        self.state = stateContext.state as Sendable
        self.fsm = stateContext.fsm
        self.environment = stateContext.environment
    }

}
