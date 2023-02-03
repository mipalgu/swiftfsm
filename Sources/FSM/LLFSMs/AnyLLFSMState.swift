public struct AnyLLFSMState<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: TypeErasedState {

    public typealias TypeErasedVersion = Self

    private let _initialContext:
        (FSMContext<FSMsContext, Environment, Parameters, Result>)
            -> AnyStateContext<FSMsContext, Environment, Parameters, Result>
    private let _onEntry: (AnyStateContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _internal: (AnyStateContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onExit: (AnyStateContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onResume: (AnyStateContext<FSMsContext, Environment, Parameters, Result>) -> Void
    private let _onSuspend: (AnyStateContext<FSMsContext, Environment, Parameters, Result>) -> Void

    public var base: Any

    public var erased: Self { self }

    public static var emptyState: AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        AnyLLFSMState(EmptyLLFSMState())
    }

    public init<Base: LLFSMState>(_ base: Base)
    where
        Base.FSMsContext == FSMsContext,
        Base.Environment == Environment,
        Base.Parameters == Parameters,
        Base.Result == Result
    {
        self.base = base
        self._initialContext = {
            StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>(
                context: Base.Context(),
                fsmContext: $0
            )
        }
        self._onEntry = {
            let context = unsafeDowncast(
                $0,
                to: StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>.self
            )
            base.onEntry(context: context)
        }
        self._internal = {
            let context = unsafeDowncast(
                $0,
                to: StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>.self
            )
            base.internal(context: context)
        }
        self._onExit = {
            let context = unsafeDowncast(
                $0,
                to: StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>.self
            )
            base.onExit(context: context)
        }
        self._onResume = {
            let context = unsafeDowncast(
                $0,
                to: StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>.self
            )
            base.onResume(context: context)
        }
        self._onSuspend = {
            let context = unsafeDowncast(
                $0,
                to: StateContext<Base.Context, FSMsContext, Environment, Parameters, Result>.self
            )
            base.onSuspend(context: context)
        }
    }

    public func initialContext(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>)
        -> AnyStateContext<FSMsContext, Environment, Parameters, Result>
    {
        _initialContext(fsmContext)
    }

    public func onEntry(context: AnyStateContext<FSMsContext, Environment, Parameters, Result>) {
        _onEntry(context)
    }

    public func `internal`(context: AnyStateContext<FSMsContext, Environment, Parameters, Result>) {
        _internal(context)
    }

    public func onExit(context: AnyStateContext<FSMsContext, Environment, Parameters, Result>) {
        _onExit(context)
    }

    public func onResume(context: AnyStateContext<FSMsContext, Environment, Parameters, Result>) {
        _onResume(context)
    }

    public func onSuspend(context: AnyStateContext<FSMsContext, Environment, Parameters, Result>) {
        _onSuspend(context)
    }

}
