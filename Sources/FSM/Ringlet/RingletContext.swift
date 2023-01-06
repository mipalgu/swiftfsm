@dynamicMemberLookup
public final class RingletContext<
    RingletsContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
> {

    public let ringlet: RingletsContext

    public let fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>

    public var fsm: FSMsContext {
        get {
            fsmContext.fsm
        } set {
            fsmContext.fsm = newValue
        }
    }

    public var environment: Environment {
        get {
            fsmContext.environment
        } set {
            fsmContext.environment = newValue
        }
    }

    public var parameters: Parameters {
        fsmContext.parameters
    }

    public var result: Result? {
        get {
            fsmContext.result
        } set {
            fsmContext.result = newValue
        }
    }

    init(ringlet: RingletsContext, fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        self.ringlet = ringlet
        self.fsmContext = fsmContext
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { fsmContext.fsm[keyPath: keyPath] }
        set { fsmContext.fsm[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Environment, T>) -> T {
        get { fsmContext.environment[keyPath: keyPath] }
        set { fsmContext.environment[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
        fsmContext.parameters[keyPath: keyPath]
    }

}
