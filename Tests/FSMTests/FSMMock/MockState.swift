import FSM

protocol MockState: StateProtocol where TypeErasedVersion == AnyMockState<OwnerContext, Environment> {

    associatedtype Context = EmptyDataStructure

    func onEntry(context: inout StateContext<Context, OwnerContext, Environment>)

    func `internal`(context: inout StateContext<Context, OwnerContext, Environment>)

    func onExit(context: inout StateContext<Context, OwnerContext, Environment>)

    func onSuspend(context: inout StateContext<Context, OwnerContext, Environment>)

    func onResume(context: inout StateContext<Context, OwnerContext, Environment>)

}

extension MockState {

    var erased: AnyMockState<OwnerContext, Environment> {
        AnyMockState(self)
    }

    func onEntry(context _: inout StateContext<Context, OwnerContext, Environment>) {}

    func `internal`(context _: inout StateContext<Context, OwnerContext, Environment>) {}

    func onExit(context _: inout StateContext<Context, OwnerContext, Environment>) {}

    func onSuspend(context _: inout StateContext<Context, OwnerContext, Environment>) {}

    func onResume(context _: inout StateContext<Context, OwnerContext, Environment>) {}

}
