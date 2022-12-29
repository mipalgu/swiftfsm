import FSM

struct CallbackMockState<
    StatesContext: DataStructure,
    FSMsContext: DataStructure,
    Environment: DataStructure
>: MockState {

    typealias Context = StatesContext
    typealias Environment = Environment
    typealias OwnerContext = FSMsContext

    private let _onEntry: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    private let _internal: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    private let _onExit: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    private let _onSuspend: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    private let _onResume: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    init(
        onEntry: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        internal: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in }
    ) {
        self._onEntry = onEntry
        self._internal = `internal`
        self._onExit = onExit
        self._onSuspend = onSuspend
        self._onResume = onResume
    }

    func onEntry(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        self._onEntry(&context)
    }

    func `internal`(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        self._internal(&context)
    }

    func onExit(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        self._onExit(&context)
    }

    func onSuspend(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        self._onSuspend(&context)
    }

    func onResume(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        self._onResume(&context)
    }

}
