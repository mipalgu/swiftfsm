@dynamicMemberLookup
public final class RingletContext<
    StateType: TypeErasedState,
    RingletsContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
> {

    var data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>

    weak var stateContainer: StateContainer<StateType, Parameters, Result, FSMsContext, Environment>!

    public var states: [FSMState<StateType, Parameters, Result, FSMsContext, Environment>] {
        stateContainer.states
    }

    public var ringletContext: RingletsContext {
        get {
            data.ringletContext
        } set {
            data.ringletContext = newValue
        }
    }

    public var fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result> {
        get {
            data.fsmContext
        } set {
            data.fsmContext = newValue
        }
    }

    public var fsm: FSMsContext {
        get {
            data.fsmContext.fsm
        } set {
            data.fsmContext.fsm = newValue
        }
    }

    public var environment: Environment {
        get {
            data.fsmContext.environment
        } set {
            data.fsmContext.environment = newValue
        }
    }

    public var parameters: Parameters {
        data.fsmContext.parameters
    }

    public var result: Result? {
        get {
            data.fsmContext.result
        } set {
            data.fsmContext.result = newValue
        }
    }

    public var status: FSMStatus {
        get {
            data.fsmContext.status
        } set {
            data.fsmContext.status = newValue
        }
    }

    public var initialState: StateID {
        data.initialState
    }

    public var currentState: StateID {
        data.currentState
    }

    public var suspendState: StateID {
        data.suspendState
    }

    public var suspendedState: StateID? {
        data.suspendedState
    }

    init(
        data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>,
        stateContainer: StateContainer<StateType, Parameters, Result, FSMsContext, Environment>? = nil
    ) {
        self.data = data
        self.stateContainer = stateContainer
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { data.fsmContext.fsm[keyPath: keyPath] }
        set { data.fsmContext.fsm[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { data.fsmContext.environment[keyPath: keyPath] }
        set { data.fsmContext.environment[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
        data.fsmContext.parameters[keyPath: keyPath]
    }

}
