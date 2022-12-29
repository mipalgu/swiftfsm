import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<Context, Environment>

    @State(name: "Ping", transitions: {
        Transition(to: \.$pong)
    })
    var ping

    @State(name: "Pong", transitions: {
        Transition(to: "Ping")
    })
    var pong

    let initialState = \Self.$ping

}
