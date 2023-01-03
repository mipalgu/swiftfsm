import FSM

struct CallbackMockState<
    StatesContext: ContextProtocol,
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: MockState {

    typealias Context = StatesContext
    typealias Environment = Environment
    typealias FSMsContext = FSMsContext
    typealias Parameters = Parameters
    typealias Result = Result

    private let _onEntry: (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _internal: (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onExit: (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onSuspend: (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    private let _onResume: (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void

    init(
        onEntry: @escaping (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void = { _ in },
        internal: @escaping (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void = { _ in },
        onExit: @escaping (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void = { _ in },
        onSuspend: @escaping (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void = { _ in },
        onResume: @escaping (inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) -> Void = { _ in }
    ) {
        self._onEntry = onEntry
        self._internal = `internal`
        self._onExit = onExit
        self._onSuspend = onSuspend
        self._onResume = onResume
    }

    func onEntry(context: inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) {
        self._onEntry(&context)
    }

    func `internal`(context: inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) {
        self._internal(&context)
    }

    func onExit(context: inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) {
        self._onExit(&context)
    }

    func onSuspend(context: inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) {
        self._onSuspend(&context)
    }

    func onResume(context: inout StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>) {
        self._onResume(&context)
    }

}
