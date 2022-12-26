import FSM

protocol MockState: StateProtocol, NameInitialisable where TypeErasedVersion == AnyMockState<Context> {

    associatedtype Context = EmptyConvertibleDataStructure<FSMMock.Context>

    func onEntry(context: inout Context)

    func main(context: inout Context)

    func onExit(context: inout Context)

    func onSuspend(context: inout Context)

    func onResume(context: inout Context)

}

extension MockState {

    var erased: AnyMockState<Context> {
        AnyMockState(self)
    }

    func onEntry(context _: inout Context) {}

    func main(context _: inout Context) {}

    func onExit(context _: inout Context) {}

    func onSuspend(context _: inout Context) {}

    func onResume(context _: inout Context) {}

}
