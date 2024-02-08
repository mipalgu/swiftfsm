import FSM
import InMemoryVariables
import LLFSMs
import Model
import XCTest

@testable import FSMTest

final class ArrangementVerifierTests: FSMTestTestCase {

    struct Converter: LLFSM {

        struct Arrangement: Model.Arrangement {

            @Actuator var valueActuator = InMemoryActuator(id: "value", initialValue: UInt8(0))

            @Sensor var distanceSensor = InMemorySensor(id: "distance", initialValue: UInt8(0))

            @Machine(
                actuators: (\.$valueActuator, mapsTo: \.$value),
                sensors: (\.$distanceSensor, mapsTo: \.$distance)
            )
            var converter = Converter()

        }

        struct Environment: EnvironmentSnapshot {

            @ReadOnly var distance: UInt8!

            @WriteOnly var value: UInt8!

        }

        @State(
            name: "Initial",
            uses: \.$distance, \.$value,
            onExit: {
                $0.value = UInt8(clamping: UInt16($0.distance) * 10)
            },
            transitions: {
                Transition(to: \.$exit)
            }
        )
        var initial

        @State(name: "Exit")
        var exit

        let initialState = \Self.$initial

    }

    struct Watchdog: LLFSM {

        struct Environment: EnvironmentSnapshot {

            @WriteOnly
            var cpuCount: UInt8!

        }

        struct Context: ContextProtocol, EmptyInitialisable {

            var previousCPUCount: UInt8 = 0

        }

        @State(
            name: "Initial",
            uses: \.$cpuCount,
            onEntry: {
                $0.cpuCount = 1
            },
            onExit: {
                $0.previousCPUCount = $0.cpuCount
                $0.cpuCount = $0.cpuCount &+ 1
                if $0.cpuCount == 0 {
                    $0.cpuCount = $0.cpuCount + 1
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
            actuators: (\.$counterControl, mapsTo: \.$cpuCount)
        )
        var watchdog = Watchdog()

    }

    struct TTSchedule: Schedule {

        let arrangement = WatchdogArrangement()

        @Slot(fsm: \.$watchdog, timing: (startTime: 1000000, duration: 2000000))
        var slot

    }

    let watchdog = Watchdog()

    let arrangement = WatchdogArrangement()

    let converterArrangement = Converter.Arrangement()

    // func testCanGenerateKripkeStructure() throws {
    //     let verifier = ArrangementVerifier(arrangement: arrangement)
    //     let schedule = TTSchedule()
    //     try verifier.generateKripkeStructures(forSchedule: schedule, formats: [.uppaal])
    // }

    func testCanGenerateConverterKripkeStructure() throws {
        let verifier = ArrangementVerifier(arrangement: converterArrangement)
        try verifier.generateKripkeStructure(formats: [.graphviz, .uppaal()])
    }

}
