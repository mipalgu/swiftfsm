@dynamicMemberLookup
public struct StateContext<
    StateContext: DataStructure, FSMsContext: DataStructure, Environment: DataStructure
> {

    public var state: StateContext

    public var fsm: FSMsContext

    public var environment: Environment

    public init(fsmContext: FSMContext<FSMsContext, Environment>) {
        // swiftlint:disable force_cast
        self.init(
            state: fsmContext.state as! StateContext,
            fsm: fsmContext.fsm,
            environment: fsmContext.environment
        )
        // swiftlint:enable force_cast
    }

    public init(state: StateContext, fsm: FSMsContext, environment: Environment) {
        self.state = state
        self.fsm = fsm
        self.environment = environment
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
        // swiftlint:disable force_cast
        state = fsmContext.state as! StateContext
        fsm = fsmContext.fsm
        environment = fsmContext.environment
        // swiftlint:enable force_cast
    }

}
