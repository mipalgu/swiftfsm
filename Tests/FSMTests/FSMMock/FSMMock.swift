import FSM

struct FSMMock: MockFSM {

    struct CustomData: DataStructure {

        var count: Int = 0

    }

    @State(name: "Ping", transitions: {
        Transition(to: \.$pong)
    })
    var ping

    @State(name: "Pong", transitions: {
        Transition(to: \.$pang)
    })
    var pong

    @State(
        name: "Pang",
        context: CustomData.self,
        main: { context in
            print("Pang: \(context.count)")
            context.count += 1
        },
        transitions: {
            Transition(to: "Ping", context: CustomData.self)
        }
    )
    var pang

    let initialState = \Self.$ping

}
