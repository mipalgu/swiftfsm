public protocol LLFSMState: StateProtocol where
    TypeErasedVersion == AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {

    associatedtype Context = EmptyDataStructure

    func onEntry(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func `internal`(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onExit(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onSuspend(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onResume(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

}

public extension LLFSMState {

    var erased: AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        AnyLLFSMState(self)
    }

    func onEntry(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func `internal`(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onExit(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onSuspend(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onResume(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

}
