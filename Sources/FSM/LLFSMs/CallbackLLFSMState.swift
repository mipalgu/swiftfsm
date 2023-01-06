public struct CallbackLLFSMState<
    StatesContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: LLFSMState {

    public typealias Context = StatesContext
    public typealias Environment = Environment
    public typealias FSMsContext = FSMsContext
    public typealias Parameters = Parameters
    public typealias Result = Result

    private let _onEntry: (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _internal: (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onExit: (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onSuspend:
        (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onResume: (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    public init(
        onEntry:
            @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
                -> Void = { _ in },
        internal:
            @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
                -> Void = { _ in },
        onExit:
            @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
                -> Void = { _ in },
        onSuspend:
            @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
                -> Void = { _ in },
        onResume:
            @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
                -> Void = { _ in }
    ) {
        self._onEntry = onEntry
        self._internal = `internal`
        self._onExit = onExit
        self._onSuspend = onSuspend
        self._onResume = onResume
    }

    public func onEntry(
        context: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self._onEntry(context)
    }

    public func `internal`(
        context: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self._internal(context)
    }

    public func onExit(
        context: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self._onExit(context)
    }

    public func onSuspend(
        context: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self._onSuspend(context)
    }

    public func onResume(
        context: StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>
    ) {
        self._onResume(context)
    }

}
