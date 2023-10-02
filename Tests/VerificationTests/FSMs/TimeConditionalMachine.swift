import FSM
import Model
import LLFSMs

struct TimeConditionalMachine: LLFSM {

    struct Context: ContextProtocol, EmptyInitialisable {

        var value = 0

    }

    @State(
        name: "Initial",
        internal: {
            if $0.after(.milliseconds(25)) {
                $0.value = 25
            } else if $0.after(.milliseconds(15)) {
                $0.value = 15
            } else if $0.after(.milliseconds(5)) {
                $0.value = 5
            } else {
                $0.value = 0
            }
        },
        onExit: {
            if $0.after(.milliseconds(25)) {
                $0.value = 25
            } else if $0.after(.milliseconds(15)) {
                $0.value = 15
            } else if $0.after(.milliseconds(5)) {
                $0.value = 5
            } else {
                $0.value = 0
            }
        },
        transitions: {
            Transition(to: \.$exit) { $0.after(.milliseconds(20)) }
        }
    )
    var initial

    @State(name: "Exit")
    var exit

    let initialState = \Self.$initial

}
