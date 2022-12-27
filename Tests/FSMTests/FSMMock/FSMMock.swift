import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<EmptyConvertibleDataStructure<EmptyDataStructure>>

    @State(transitions: {
        Transition<EmptyMockState>(to: \.$pong)
    })
    var ping = EmptyMockState(name: "Ping")

    @State(transitions: {
        Transition<EmptyMockState>(to: "Ping")
    })
    var pong = EmptyMockState(name: "Pong")

    let initialState = \Self.$ping

}
