import FSM

struct AnyMockState<Context: DataStructure>: StateProtocol, TypeErasedState, Nameable {

    typealias TypeErasedVersion = Self

    private let _name: () -> String
    private let _onEntry: (inout Context) -> Void
    private let _main: (inout Context) -> Void
    private let _onExit: (inout Context) -> Void
    private let _onResume: (inout Context) -> Void
    private let _onSuspend: (inout Context) -> Void

    var base: Any

    var name: String { _name() }

    var erased: Self { self }

    init<Base: MockState>(_ base: Base) where Base.Context == Context {
        self.base = base
        self._name = { base.name }
        self._onEntry = { base.onEntry(context: &$0) }
        self._main = { base.main(context: &$0) }
        self._onExit = { base.onExit(context: &$0) }
        self._onResume = { base.onResume(context: &$0) }
        self._onSuspend = { base.onSuspend(context: &$0) }
    }

    func onEntry(context: inout Context) {
        _onEntry(&context)
    }

    func main(context: inout Context) {
        _main(&context)
    }

    func onExit(context: inout Context) {
        _onExit(&context)
    }

    func onResume(context: inout Context) {
        _onResume(&context)
    }

    func onSuspend(context: inout Context) {
        _onSuspend(&context)
    }

}
