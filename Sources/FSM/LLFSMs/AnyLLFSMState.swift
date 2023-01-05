public struct AnyLLFSMState<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: TypeErasedState {

    public typealias Context = FSMContext<FSMsContext, Environment, Parameters, Result>
    public typealias TypeErasedVersion = Self

    private let _onEntry: (inout FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _internal: (inout FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onExit: (inout FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onResume: (inout FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onSuspend: (inout FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void

    public var base: Any

    public var erased: Self { self }

    public static var empty: (Sendable, AnyLLFSMState<FSMsContext, Environment, Parameters, Result>) {
        (EmptyDataStructure(), AnyLLFSMState(EmptyLLFSMState()))
    }

    public init<Base: LLFSMState>(_ base: Base)
        where Base.FSMsContext == FSMsContext,
            Base.Environment == Environment,
            Base.Parameters == Parameters,
            Base.Result == Result {
        self.base = base
        self._onEntry = {
            var context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(fsmContext: $0)
            base.onEntry(context: &context)
            $0.update(from: context)
        }
        self._internal = {
            var context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(fsmContext: $0)
            base.internal(context: &context)
            $0.update(from: context)
        }
        self._onExit = {
            var context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(fsmContext: $0)
            base.onExit(context: &context)
            $0.update(from: context)
        }
        self._onResume = {
            var context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(fsmContext: $0)
            base.onResume(context: &context)
            $0.update(from: context)
        }
        self._onSuspend = {
            var context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(fsmContext: $0)
            base.onSuspend(context: &context)
            $0.update(from: context)
        }
    }

    public func onEntry(context: inout FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onEntry(&context)
    }

    public func `internal`(context: inout FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _internal(&context)
    }

    public func onExit(context: inout FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onExit(&context)
    }

    public func onResume(context: inout FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onResume(&context)
    }

    public func onSuspend(context: inout FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onSuspend(&context)
    }

}
