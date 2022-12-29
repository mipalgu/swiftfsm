import FSM

struct AnyMockState<
    FSMsContext: DataStructure,
    Environment: DataStructure
>: TypeErasedState {

    typealias Context = FSMContext<FSMsContext, Environment>
    typealias TypeErasedVersion = Self

    private let _onEntry: (inout FSMContext<FSMsContext, Environment>) -> Void
    private let _internal: (inout FSMContext<FSMsContext, Environment>) -> Void
    private let _onExit: (inout FSMContext<FSMsContext, Environment>) -> Void
    private let _onResume: (inout FSMContext<FSMsContext, Environment>) -> Void
    private let _onSuspend: (inout FSMContext<FSMsContext, Environment>) -> Void

    var base: Any

    var erased: Self { self }

    init<Base: MockState>(_ base: Base)
        where Base.FSMsContext == FSMsContext,
            Base.Environment == Environment {
        self.base = base
        self._onEntry = {
            var context = StateContext<Base.Context, FSMsContext, Environment>(fsmContext: $0)
            base.onEntry(context: &context)
            $0.update(from: context)
        }
        self._internal = {
            var context = StateContext<Base.Context, FSMsContext, Environment>(fsmContext: $0)
            base.internal(context: &context)
            $0.update(from: context)
        }
        self._onExit = {
            var context = StateContext<Base.Context, FSMsContext, Environment>(fsmContext: $0)
            base.onExit(context: &context)
            $0.update(from: context)
        }
        self._onResume = {
            var context = StateContext<Base.Context, FSMsContext, Environment>(fsmContext: $0)
            base.onResume(context: &context)
            $0.update(from: context)
        }
        self._onSuspend = {
            var context = StateContext<Base.Context, FSMsContext, Environment>(fsmContext: $0)
            base.onSuspend(context: &context)
            $0.update(from: context)
        }
    }

    func onEntry(context: inout FSMContext<FSMsContext, Environment>) {
        _onEntry(&context)
    }

    func `internal`(context: inout FSMContext<FSMsContext, Environment>) {
        _internal(&context)
    }

    func onExit(context: inout FSMContext<FSMsContext, Environment>) {
        _onExit(&context)
    }

    func onResume(context: inout FSMContext<FSMsContext, Environment>) {
        _onResume(&context)
    }

    func onSuspend(context: inout FSMContext<FSMsContext, Environment>) {
        _onSuspend(&context)
    }

}
