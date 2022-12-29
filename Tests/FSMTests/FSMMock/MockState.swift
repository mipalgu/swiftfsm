import FSM

protocol MockState: StateProtocol, NameInitialisable
    where TypeErasedVersion == AnyMockState<OwnerContext, OwnerEnvironment> {

    associatedtype Context = EmptyConvertibleDataStructure<FSMMock.Context>

    func onEntry(context: inout StateContext<Context, OwnerContext, OwnerEnvironment>)

    func main(context: inout StateContext<Context, OwnerContext, OwnerEnvironment>)

    func onExit(context: inout StateContext<Context, OwnerContext, OwnerEnvironment>)

    func onSuspend(context: inout StateContext<Context, OwnerContext, OwnerEnvironment>)

    func onResume(context: inout StateContext<Context, OwnerContext, OwnerEnvironment>)

}

extension MockState {

    var erased: AnyMockState<OwnerContext, OwnerEnvironment> {
        AnyMockState(self)
    }

    func onEntry(context _: inout StateContext<Context, OwnerContext, OwnerEnvironment>) {}

    func main(context _: inout StateContext<Context, OwnerContext, OwnerEnvironment>) {}

    func onExit(context _: inout StateContext<Context, OwnerContext, OwnerEnvironment>) {}

    func onSuspend(context _: inout StateContext<Context, OwnerContext, OwnerEnvironment>) {}

    func onResume(context _: inout StateContext<Context, OwnerContext, OwnerEnvironment>) {}

}
