import FSM

struct EmptyMockState<FSMsContext: ContextProtocol, Environment: EnvironmentSnapshot>: MockState {

    typealias Context = EmptyDataStructure
    typealias Environment = Environment
    typealias FSMsContext = FSMsContext

}
