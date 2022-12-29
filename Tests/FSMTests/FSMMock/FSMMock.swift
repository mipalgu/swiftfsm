import FSM

struct FSMMock: MockFSM {

    typealias Environment = EnvironmentStruct

    struct EnvironmentStruct: EnvironmentVariables {

        struct Data: DataStructure, EmptyInitialisable {

            var exit: Bool = false

        }

        @Sensor(handler: InMemorySensor<Bool>(id: "exit", initialValue: false), mapsTo: \.exit)
        var exit

    }

    struct Context: DataStructure {

        var fsmCount: Int = 0

    }

    struct PangData: DataStructure {

        var stateCount: Int = 0

    }

    @State(name: "Ping")
    var ping

    // @State(
    //     name: "Pong",
    //     onEntry: { print("Pong: \($0.fsmCount)") },
    //     onExit: { $0.fsmCount += 1 },
    //     transitions: {
    //         Transition(to: \.$pang)
    //     }
    // )
    // var pong

    // @State(
    //     name: "Pang",
    //     context: PangData.self,
    //     onEntry: { $0.stateCount = 0 },
    //     internal: {
    //         print("Pang: (\($0.fsmCount), \($0.stateCount))")
    //         $0.stateCount += 1
    //         $0.fsmCount += 1
    //     },
    //     transitions: {
    //         Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
    //     }
    // )
    // var pang

    let initialState = \Self.$ping

}
