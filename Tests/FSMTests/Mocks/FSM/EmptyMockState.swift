import FSM

struct EmptyMockState<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: MockState {

    typealias Context = EmptyDataStructure
    typealias Environment = Environment
    typealias FSMsContext = FSMsContext
    typealias Parameters = Parameters
    typealias Result = Result

}
