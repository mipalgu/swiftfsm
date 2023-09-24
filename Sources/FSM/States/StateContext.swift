@dynamicMemberLookup
public final class StateContext<
    StateContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: AnyStateContext<FSMsContext, Environment, Parameters, Result> {

    public var context: StateContext

    public override var customMirror: Mirror {
        Mirror(reflecting: context)
    }

    public var fsm: FSMsContext {
        get {
            fsmContext.context
        }
        set {
            fsmContext.context = newValue
        }
    }

    public var environment: Environment {
        get {
            fsmContext.environment
        }
        set {
            fsmContext.environment = newValue
        }
    }

    public var parameters: Parameters {
        fsmContext.parameters
    }

    public var result: Result? {
        get {
            fsmContext.result
        }
        set {
            fsmContext.result = newValue
        }
    }

    var status: FSMStatus {
        get {
            fsmContext.status
        }
        set {
            fsmContext.status = newValue
        }
    }

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

    public init(context: StateContext, fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.context = context
        super.init(fsmContext: fsmContext)
    }

    public func after(_ duration: Duration) -> Bool {
        fsmContext.after(duration)
    }

    override public func clone(
        fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>
    ) -> AnyStateContext<FSMsContext, Environment, Parameters, Result> {
        Self(context: context, fsmContext: fsmContext)
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<StateContext, T>) -> T {
        get { context[keyPath: keyPath] }
        set { context[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { fsm[keyPath: keyPath] }
        set { fsm[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { environment[keyPath: keyPath] }
        set { environment[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
        parameters[keyPath: keyPath]
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

}
