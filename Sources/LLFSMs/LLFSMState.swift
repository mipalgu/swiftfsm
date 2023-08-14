import FSM

public protocol LLFSMState: StateProtocol
where
    TypeErasedVersion == AnyLLFSMState<FSMsContext, Environment, Parameters, Result>
{

    associatedtype Context = EmptyDataStructure

    var initialContext: Context { get }

    func onEntry(context: StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func `internal`(context: StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onExit(context: StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onSuspend(context: StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onResume(context: StateContext<Context, FSMsContext, Environment, Parameters, Result>)

}

extension LLFSMState {

    public var erased: AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        AnyLLFSMState(self, initialContext: initialContext)
    }

    public func onEntry(context _: StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    public func `internal`(context _: StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    public func onExit(context _: StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    public func onSuspend(context _: StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    public func onResume(context _: StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

}

extension LLFSMState where Context: EmptyInitialisable {

    public var initialContext: Context { Context() }

}
