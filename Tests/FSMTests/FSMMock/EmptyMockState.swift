import FSM

struct EmptyMockState<FSMsContext: DataStructure, Environment: EnvironmentSnapshot>: MockState {

    typealias Context = EmptyDataStructure
    typealias Environment = Environment
    typealias FSMsContext = FSMsContext

}
