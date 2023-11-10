import FSM
import InMemoryVariables
import LLFSMs
import Model

public struct FSMMock: LLFSM {

    public struct Context: ContextProtocol, EmptyInitialisable {

        public var fsmCount: Int = 0

        public init() {}

    }

    //    struct Dependencies: DataStructure, EmptyInitialisable {
    //
    //        @Sync(name: "Me")
    //        var Me
    //
    //        init() {}
    //
    //    }

    public struct Environment: EnvironmentProtocol {

        @WriteOnly
        public var exitActuator: Bool!

        @ReadWrite
        public var exitExternalVariable: Bool!

        @ReadWrite
        public var exitGlobalVariable: Bool!

        @ReadOnly
        public var exitSensor: Bool!

        public init() {}
    }

    public struct PangData: ContextProtocol {

        public var stateCount: Int = 0

        public init() {}

    }

    @State(
        name: "Ping",
        onExit: { $0.fsmCount += 1 },
        transitions: {
            Transition(to: \.$pong)
        }
    )
    public var ping

    @State(
        name: "Pong",
        onExit: { $0.fsmCount += 1 },
        transitions: {
            Transition(to: \.$pang)
        }
    )
    public var pong

    @State(
        name: "Pang",
        initialContext: PangData(),
        uses: \.$exitSensor,
        onEntry: { $0.stateCount = 0 },
        internal: {
            $0.stateCount += 1
            $0.fsmCount += 1
        },
        transitions: {
            Transition(to: \.$exit, context: PangData.self) { $0.exitSensor }
            Transition(to: "Ping", context: PangData.self) { $0.stateCount > 5 }
        }
    )
    public var pang

    @State(name: "Exit", onEntry: { _ in print("Exit") })
    public var exit

    public let initialState = \Self.$ping

    public init() {}

}
