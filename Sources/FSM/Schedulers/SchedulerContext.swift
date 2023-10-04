private struct StateRepresentation {

    var name: String

    var variables: Any

}

@dynamicMemberLookup
public final class SchedulerContext<
    StateType: TypeErasedState,
    RingletsContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: AnySchedulerContext {

    override public var afterCalls: [Duration] {
        get {
            fsmContext.afterCalls
        } set {
            fsmContext.afterCalls = newValue
        }
    }

    public var data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>

    public weak var stateContainer: StateContainer<StateType, Parameters, Result, FSMsContext, Environment>!

    override public var cloned: AnySchedulerContext {
        let clone = Self(
            fsmID: fsmID,
            fsmName: fsmName,
            data: data.cloned,
            stateContainer: stateContainer
        )
        clone.duration = super.duration
        clone.transitioned = super.transitioned
        clone.startTime = startTime
        return clone
    }

    public override var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "currentState": data.currentState,
                "environment": data.fsmContext.environment,
                "isFinished": data.fsmContext.isFinished,
                "isSuspended": data.fsmContext.isSuspended,
                "name": super.fsmName,
                "parameters": data.fsmContext.parameters,
                "result": data.fsmContext.result as Any,
                "ringlet": data.ringletContext,
                "states": Dictionary(uniqueKeysWithValues: stateContainer.states.map {
                    ($0.id, StateRepresentation(name: $0.name, variables: data.stateContexts[$0.id]))
                }),
                "status": status,
                "variables": data.fsmContext.context
            ],
            displayStyle: .class,
            ancestorRepresentation: .suppressed
        )
    }

    public var states: [FSMState<StateType, Parameters, Result, FSMsContext, Environment>] {
        stateContainer.states
    }

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

    override public var typeErasedResult: Sendable? {
        data.fsmContext.result
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

    override public var currentState: StateID {
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
        data: FSMData<RingletsContext, Parameters, Result, FSMsContext, Environment>,
        stateContainer: StateContainer<StateType, Parameters, Result, FSMsContext, Environment>? = nil
    ) {
        self.data = data
        self.stateContainer = stateContainer
        super.init(fsmID: fsmID, fsmName: fsmName)
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
