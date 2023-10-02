import FSM
import LLFSMs
import Model

struct TestMachine: LLFSM {

    struct Environment: EnvironmentSnapshot {

        @ReadWrite
        var externalCount: Int!

    }

    struct Context: ContextProtocol, EmptyInitialisable {

        var count: Int = 0

    }

    struct InitialStateContext: ContextProtocol, EmptyInitialisable {

        var stateCount: Int = 0

    }

    @State(
        name: "Initial",
        initialContext: InitialStateContext(),
        uses: \.$externalCount,
        onEntry: {
            $0.count += 1
            $0.externalCount = $0.externalCount &+ 1
        },
        internal: {
            $0.stateCount += 1
        },
        onExit: {
            $0.stateCount += 1
        },
        transitions: {
            Transition(to: \.$exit, context: InitialStateContext.self) {
                $0.stateCount >= 2 || $0.after(.seconds(2))
            }
        }
    )
    var initial

    @State(name: "Exit")
    var exit

    var initialState = \Self.$initial

}
