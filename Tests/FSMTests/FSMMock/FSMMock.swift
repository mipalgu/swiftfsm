import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<EmptyConvertibleDataStructure<EmptyDataStructure>>

    @State(transitions: {
        Transition<EmptyMockState>(to: \FSMMock.$pong)
    })
    var ping = EmptyMockState(name: "Ping")

    @State(transitions: {
        Transition<EmptyMockState>(to: "Ping")
    })
    var pong = EmptyMockState(name: "Pong")

    var initialState: StateID {
        id(of: \.$ping)
    }

}
