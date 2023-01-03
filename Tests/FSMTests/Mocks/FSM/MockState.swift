import FSM

protocol MockState: StateProtocol where
    TypeErasedVersion == AnyMockState<FSMsContext, Environment, Parameters, Result> {

    associatedtype Context = EmptyDataStructure

    func onEntry(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func `internal`(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onExit(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onSuspend(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

    func onResume(context: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>)

}

extension MockState {

    var erased: AnyMockState<FSMsContext, Environment, Parameters, Result> {
        AnyMockState(self)
    }

    func onEntry(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func `internal`(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onExit(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onSuspend(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

    func onResume(context _: inout StateContext<Context, FSMsContext, Environment, Parameters, Result>) {}

}
