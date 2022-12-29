import FSM

struct EmptyMockState<FSMsContext: DataStructure, Environment: DataStructure>: MockState {

    typealias Context = EmptyDataStructure
    typealias Environment = Environment
    typealias OwnerContext = FSMsContext

}
