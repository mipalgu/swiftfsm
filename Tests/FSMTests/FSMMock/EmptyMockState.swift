import FSM

struct EmptyMockState: MockState {

    typealias Context = EmptyConvertibleDataStructure<FSMMock.Context>

}
