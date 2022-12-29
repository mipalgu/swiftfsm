import FSM

struct NamedMockState: MockState {

    typealias Context = EmptyConvertibleDataStructure<FSMMock.Context>

    let name: String

}
