import FSM

struct FSMMock: FSMModel {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<Context, Environment>

    @State(name: "Ping", transitions2: {
        Transition(to: \Self.$pong)
    })
    var ping

    @State(name: "Pong")
    var pong

    let initialState = \Self.$ping

}
