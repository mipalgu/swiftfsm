import FSM
import InMemoryVariables
import LLFSMs
import Model
import XCTest

@testable import FSMTest

final class ArrangementVerifierTests: XCTestCase {

    struct Watchdog: LLFSM {

        struct Environment: EnvironmentSnapshot {

            @WriteOnly
            var counter: UInt8!

        }

        @State(
            name: "Initial",
            uses: \.$counter,
            onEntry: {
                $0.counter = 1
            },
            onExit: {
                $0.counter = $0.counter &+ 1
                if $0.counter == 0 {
                    $0.counter = $0.counter + 1
                }
            },
            transitions: {
                Transition(to: "Initial") { $0.after(.milliseconds(5)) }
            }
        )
        var initial

        let initialState = \Self.$initial

    }

    struct WatchdogArrangement: Arrangement {

        @Actuator
        var counterControl = InMemoryActuator(id: "counter", initialValue: UInt8(1))

        @Machine(
            actuators: (\.$counterControl, mapsTo: \.$counter)
        )
        var watchdog = Watchdog()

    }

    let watchdog = Watchdog()

    let arrangement = WatchdogArrangement()

    func testCanGenerateKripkeStructure() throws {
        let verifier = ArrangementVerifier(arrangement: arrangement)
        try verifier.generateKripkeStructure(formats: [.nuXmv, .graphviz], usingClocks: false)
    }

}
