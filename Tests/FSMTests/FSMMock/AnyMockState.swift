import FSM

struct AnyMockState<
    StatesContext: DataStructure,
    FSMsContext: DataStructure,
    Environment: DataStructure
>: StateProtocol, TypeErasedState, Nameable {

    typealias Context = StatesContext
    typealias TypeErasedVersion = Self

    private let _name: () -> String
    private let _onEntry: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void
    private let _main: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void
    private let _onExit: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void
    private let _onResume: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void
    private let _onSuspend: (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void

    var base: Any

    var name: String { _name() }

    var erased: Self { self }

    init<Base: MockState>(_ base: Base) where Base.Context == StatesContext, Base.OwnerContext == FSMsContext, Base.OwnerEnvironment == Environment {
        self.base = base
        self._name = { base.name }
        self._onEntry = { base.onEntry(context: &$0) }
        self._main = { base.main(context: &$0) }
        self._onExit = { base.onExit(context: &$0) }
        self._onResume = { base.onResume(context: &$0) }
        self._onSuspend = { base.onSuspend(context: &$0) }
    }

    func onEntry(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        _onEntry(&context)
    }

    func main(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        _main(&context)
    }

    func onExit(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        _onExit(&context)
    }

    func onResume(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        _onResume(&context)
    }

    func onSuspend(context: inout StateContext<StatesContext, FSMsContext, Environment>) {
        _onSuspend(&context)
    }

}
