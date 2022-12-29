import FSM

struct EmptyMockState<FSMsContext: DataStructure, Environment: DataStructure>: MockState {

    typealias Context = EmptyDataStructure
    typealias Environment = EmptyDataStructure
    typealias OwnerContext = FSMsContext
    typealias OwnerEnvironment = Environment

}
