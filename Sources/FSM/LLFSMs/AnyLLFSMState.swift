public struct AnyLLFSMState<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: TypeErasedState {

    public typealias Context = FSMContext<FSMsContext, Environment, Parameters, Result>
    public typealias TypeErasedVersion = Self

    private let _onEntry: (FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _internal: (FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onExit: (FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onResume: (FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onSuspend: (FSMContext<FSMsContext, Environment, Parameters, Result>) -> Void

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
            let context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                fsmContext: $0
            )
            base.onEntry(context: context)
            $0.update(from: context)
        }
        self._internal = {
            let context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                fsmContext: $0
            )
            base.internal(context: context)
            $0.update(from: context)
        }
        self._onExit = {
            let context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                fsmContext: $0
            )
            base.onExit(context: context)
            $0.update(from: context)
        }
        self._onResume = {
            let context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                fsmContext: $0
            )
            base.onResume(context: context)
            $0.update(from: context)
        }
        self._onSuspend = {
            let context = StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                fsmContext: $0
            )
            base.onSuspend(context: context)
            $0.update(from: context)
        }
    }

    public func onEntry(context: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onEntry(context)
    }

    public func `internal`(context: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _internal(context)
    }

    public func onExit(context: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onExit(context)
    }

    public func onResume(context: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onResume(context)
    }

    public func onSuspend(context: FSMContext<FSMsContext, Environment, Parameters, Result>) {
        _onSuspend(context)
    }

}
