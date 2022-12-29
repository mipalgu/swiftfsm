import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<Context, Environment>

    @State(name: "Ping", transitions: {
        Transition<EmptyMockState<EmptyDataStructure, EmptyDataStructure>>(to: \.$pong)
    })
    var ping = EmptyMockState()

    @State(name: "Pong", transitions: {
        Transition<EmptyMockState<EmptyDataStructure, EmptyDataStructure>>(to: "Ping")
    })
    var pong = EmptyMockState()

    let initialState = \Self.$ping

}
