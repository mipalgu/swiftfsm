import FSM

protocol MockState: StateProtocol where TypeErasedVersion == AnyMockState<FSMsContext, Environment> {

    associatedtype Context = EmptyDataStructure

    func onEntry(context: inout StateContext<Context, FSMsContext, Environment>)

    func `internal`(context: inout StateContext<Context, FSMsContext, Environment>)

    func onExit(context: inout StateContext<Context, FSMsContext, Environment>)

    func onSuspend(context: inout StateContext<Context, FSMsContext, Environment>)

    func onResume(context: inout StateContext<Context, FSMsContext, Environment>)

}

extension MockState {

    var erased: AnyMockState<FSMsContext, Environment> {
        AnyMockState(self)
    }

    func onEntry(context _: inout StateContext<Context, FSMsContext, Environment>) {}

    func `internal`(context _: inout StateContext<Context, FSMsContext, Environment>) {}

    func onExit(context _: inout StateContext<Context, FSMsContext, Environment>) {}

    func onSuspend(context _: inout StateContext<Context, FSMsContext, Environment>) {}

    func onResume(context _: inout StateContext<Context, FSMsContext, Environment>) {}

}
