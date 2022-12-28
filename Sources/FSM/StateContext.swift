@dynamicMemberLookup
public struct StateContext<
    StateContext: DataStructure, FSMsContext: DataStructure, Environment: DataStructure
> {

    public var state: StateContext

    public var fsm: FSMsContext

    public var environment: Environment

    private var status: FSMStatus

    public var isFinished: Bool {
        status == .finished
    }

    public var isSuspended: Bool {
        status == .suspended
    }

    public init(fsmContext: FSMContext<FSMsContext, Environment>) {
        // swiftlint:disable force_cast
        self.init(
            state: fsmContext.state as! StateContext,
            fsm: fsmContext.fsm,
            environment: fsmContext.environment,
            status: fsmContext.status
        )
        // swiftlint:enable force_cast
    }

    public init(
        state: StateContext,
        fsm: FSMsContext,
        environment: Environment,
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
        environment[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { environment[keyPath: keyPath] }
        set { environment[keyPath: keyPath] = newValue }
    }

    public mutating func update(from fsmContext: FSMContext<FSMsContext, Environment>) {
        // swiftlint:disable:next force_cast
        state = fsmContext.state as! StateContext
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
