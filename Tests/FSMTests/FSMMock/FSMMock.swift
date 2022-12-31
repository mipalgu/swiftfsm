import FSM

struct FSMMock: MockFSM {

    struct Environment: EnvironmentSnapshot {

        var exitActuator: Bool!

        var exitExternalVariable: Bool!

        fileprivate(set) var exitSensor: Bool!
    }

    struct Context: DataStructure {

        var fsmCount: Int = 0

    }

    struct PangData: DataStructure {

        var stateCount: Int = 0

    }

    @Actuator(handler: InMemoryActuator<Bool>(id: "exit", initialValue: false), mapsTo: \.exitActuator)
    var exitActuator

    @ExternalVariable(
        handler: InMemoryExternalVariable<Bool>(id: "exit", initialValue: false),
        mapsTo: \.exitExternalVariable
    )
    var exitExternalVariable

    @Sensor(handler: InMemorySensor<Bool>(id: "exit", initialValue: false), mapsTo: \.exitSensor)
    var exitSensor

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
        uses: \.exitSensor,
        onEntry: { $0.stateCount = 0 },
        internal: {
            print("Pang: (\($0.fsmCount), \($0.stateCount))")
            $0.stateCount += 1
            $0.fsmCount += 1
        },
        transitions: {
            Transition(to: \.$exit, context: PangData.self) { $0.exitSensor }
            Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
        }
    )
    var pang

    @State(name: "Exit")
    var exit

    let initialState = \Self.$ping

}
