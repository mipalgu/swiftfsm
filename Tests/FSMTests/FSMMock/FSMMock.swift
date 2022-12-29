import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<Context, Environment>

    @State(name: "Ping", transitions: {
        Transition<EmptyMockState>(to: \.$pong)
    })
    var ping = EmptyMockState()

    @State(name: "Pong", transitions: {
        Transition<EmptyMockState>(to: "Ping")
    })
    var pong = EmptyMockState()

    let initialState = \Self.$ping

}
