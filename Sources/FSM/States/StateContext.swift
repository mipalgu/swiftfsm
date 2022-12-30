@dynamicMemberLookup
public struct StateContext<
    StateContext: DataStructure, FSMsContext: DataStructure, Environment: EnvironmentSnapshot
> {

    public var state: StateContext

    public var fsm: FSMsContext

    public var environment: Snapshot<Environment>

    private var status: FSMStatus

    public var isFinished: Bool {
        status == .finished
    }

    public var isSuspended: Bool {
        status == .suspended
    }

    public init(fsmContext: FSMContext<FSMsContext, Environment>) {
        self.init(
            state: unsafeBitCast(fsmContext.state, to: StateContext.self),
            fsm: fsmContext.fsm,
            environment: fsmContext.environment,
            status: fsmContext.status
        )
    }

    public init(
        state: StateContext,
        fsm: FSMsContext,
        environment: Snapshot<Environment>,
        status: FSMStatus = .executing
    ) {
        self.state = state
        self.fsm = fsm
        self.environment = environment
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
        environment.get(keyPath)
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { environment.get(keyPath) }
        set { environment.set(keyPath, newValue) }
    }

    public mutating func update(from fsmContext: FSMContext<FSMsContext, Environment>) {
        state = unsafeBitCast(fsmContext.state, to: StateContext.self)
        fsm = fsmContext.fsm
        environment = fsmContext.environment
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
