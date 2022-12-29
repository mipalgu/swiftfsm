import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<Context, Environment>

    @State(name: "Ping", transitions: {
        Transition<EmptyMockState>(to: \.$pong)
    })
    var ping = EmptyMockState(name: "Ping")

    @State(name: "Pong", transitions: {
        Transition<EmptyMockState>(to: "Ping")
    })
    var pong = EmptyMockState(name: "Pong")

    let initialState = \Self.$ping

}
