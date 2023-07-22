@dynamicMemberLookup
public final class FSMContext<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: FiniteStateMachineOperations {

    public var context: FSMsContext

    internal var duration: Duration = .zero

    public var environment: Environment

    public let parameters: Parameters

    public var result: Result?

    public internal(set) var status: FSMStatus

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

    public convenience init(
        context: FSMsContext,
        environment: Environment,
        parameters: Parameters,
        result: Result?
    ) {
        self.init(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result,
            status: .executing(transitioned: true)
        )
    }

    init(
        context: FSMsContext,
        environment: Environment,
        parameters: Parameters,
        result: Result?,
        status: FSMStatus
    ) {
        self.context = context
        self.environment = environment
        self.parameters = parameters
        self.result = result
        self.status = status
    }

    public func after(_ duration: Duration) -> Bool {
        self.duration > duration
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<FSMsContext, T>) -> T {
        context[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<FSMsContext, T>) -> T {
        get { context[keyPath: keyPath] }
        set { context[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Environment, T>) -> T {
        environment[keyPath: keyPath]
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
