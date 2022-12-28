@dynamicMemberLookup
public struct StateContext<
    StateContext: DataStructure, FSMContext: DataStructure, Environment: DataStructure
> {

    private var state: StateContext

    private var fsm: FSMContext

    private var environment: Environment

    public init(state: StateContext, fsm: FSMContext, environment: Environment) {
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

    public subscript<T>(dynamicMember keyPath: KeyPath<FSMContext, T>) -> T {
        fsm[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMContext, T>) -> T {
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

}
