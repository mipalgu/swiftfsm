import FSM
import FSMTest
import XCTest

@testable import Verification

final class VerificationStepGeneratorTests: XCTestCase {

    let generator = VerificationStepGenerator()

    var bool1 = false

    var bool2 = false

    var model: BoolsMachine!

    var info: FSMInformation!

    var fsm: (any Executable)!

    var context: AnySchedulerContext!

    var pool: ExecutablePool!

    var timeslot: Timeslot!

    var contexts: [VerificationContext] = []

    override func setUp() {
        let bool1Handler = MockedExternalVariable(id: "bool1", initialValue: false) {
            self.bool1
        } saveSnapshot: {
            self.bool1 = $0
        }
        let bool2Handler = MockedExternalVariable(id: "bool2", initialValue: false) {
            self.bool2
        } saveSnapshot: {
            self.bool2 = $0
        }
        self.model = BoolsMachine()
        let (executable, contextFactory) = model.initial(
            actuators: [],
            externalVariables: [
                erase(bool1Handler, mapsTo: \.$bool1),
                erase(bool2Handler, mapsTo: \.$bool2)
            ],
            globalVariables: [],
            sensors: []
        )
        let info = FSMInformation(fsm: model)
        self.fsm = executable
        self.context = contextFactory(nil)
        self.pool = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
        self.timeslot = Timeslot(
            executables: [info.id],
            callChain: CallChain(root: info.id, calls: []),
            externalDependencies: [],
            startingTime: .zero,
            duration: .nanoseconds(30),
            cyclesExecuted: 0
        )
        fsm.next(context: context) // Move the fsm past the initial pseudo state.
        bool1 = false
        bool2 = false
        fsm.takeSnapshot(context: context) // Set environment variables.
        contexts = [VerificationContext(information: info, handlers: fsm.handlers)]
    }

    func testTakeSnapshot() {
        XCTAssertEqual(generator.takeSnapshot(forFsms: contexts, in: pool).count, 4)
    }

}
