import FSM

struct FSMMock: FiniteStateMachineProtocol {

    typealias Context = EmptyDataStructure
    typealias StateType = AnyMockState<EmptyConvertibleDataStructure<EmptyDataStructure>>

    var context = EmptyDataStructure()

    let name = "FSM"

    @State(transitions: {
        Transition<EmptyMockState>(to: \FSMMock.$pong)
    })
    var ping = EmptyMockState(name: "Ping")

    @State(transitions: {
        Transition<EmptyMockState>(to: "Ping")
    })
    var pong = EmptyMockState(name: "Pong")

    var currentState = id(of: "Ping")

    var initialState = id(of: "Ping")

    private(set) var isFinished: Bool = false

    var isSuspended: Bool = false

    mutating func restart() {}

    mutating func resume() {}

    mutating func suspend() {}

    mutating func next() {}

}
