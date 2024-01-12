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

    // func testCanGenerateKripkeStructure() throws {
    //     let path = URL(fileURLWithPath: #filePath, isDirectory: false)
    //         .deletingLastPathComponent()
    //         .deletingLastPathComponent()
    //         .deletingLastPathComponent()
    //         .appendingPathComponent("kripke_structures")
    //     let fm = FileManager()
    //     _ = try? fm.createDirectory(at: path, withIntermediateDirectories: true)
    //     let moved = fm.changeCurrentDirectoryPath(path.path)
    //     defer {
    //         if moved { _ = fm.changeCurrentDirectoryPath(path.deletingLastPathComponent().path) }
    //     }
    //     let verifier = ArrangementVerifier(arrangement: arrangement)
    //     let schedule = TTSchedule()
    //     try verifier.generateKripkeStructures(forSchedule: schedule, formats: [.uppaal])
    // }

}
