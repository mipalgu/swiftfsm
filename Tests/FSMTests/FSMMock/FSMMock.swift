import FSM

struct FSMMock: MockFSM {

    struct Context: DataStructure {

        var fsmCount: Int = 0

    }

    struct PangData: DataStructure {

        var stateCount: Int = 0

    }

    @State(
        name: "Ping",
        onEntry: { print("Ping: \($0.fsmCount)") },
        onExit: { $0.fsmCount += 1 },
        transitions: {
            Transition(to: \.$pong)
        }
    )
    var ping

    @State(
        name: "Pong",
        onEntry: { print("Pong: \($0.fsmCount)") },
        onExit: { $0.fsmCount += 1 },
        transitions: {
            Transition(to: \.$pang)
        }
    )
    var pong

    @State(
        name: "Pang",
        context: PangData.self,
        onEntry: { $0.stateCount = 0 },
        internal: {
            print("Pang: (\($0.fsmCount), \($0.stateCount))")
            $0.stateCount += 1
            $0.fsmCount += 1
        },
        transitions: {
            Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
        }
    )
    var pang

    let initialState = \Self.$ping

}
