import FSM
import KripkeStructure
import XCTest

@testable import Verification

final class ConditionalRingletTests: XCTestCase {

    let model = EmptyMachine()

    var info: FSMInformation!

    var executable: (any Executable)!

    var context: AnySchedulerContext!

    var before: ExecutablePool!

    var after: ExecutablePool!

    var timeslot: Timeslot!

    var transitioned = false

    var preSnapshot: KripkeStatePropertyList!

    var postSnapshot: KripkeStatePropertyList!

    var calls: [Call] = []

    var condition: Constraint<UInt>!

    var ringlet: ConditionalRinglet!

    override func setUp() {
        info = FSMInformation(fsm: model)
        let (fsm, contextFactory) = model.initial(
            actuators: [],
            externalVariables: [],
            globalVariables: [],
            sensors: []
        )
        executable = fsm
        context = contextFactory(nil)
        before = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
        after = before.cloned
        timeslot = Timeslot(
            executables: [info.id],
            callChain: CallChain(root: info.id, calls: []),
            startingTime: 0,
            duration: 30,
            cyclesExecuted: 0
        )
        transitioned = false
        preSnapshot = [
            "value": KripkeStateProperty(true)
        ]
        postSnapshot = [
            "value": KripkeStateProperty(false)
        ]
        calls = []
        condition = Constraint<UInt>.greaterThanEqual(value: 0)
        ringlet = ConditionalRinglet(
            timeslot: timeslot,
            before: before,
            after: after,
            transitioned: transitioned,
            preSnapshot: preSnapshot,
            postSnapshot: postSnapshot,
            calls: calls,
            condition: condition
        )
    }

    func testInit() {
        XCTAssertEqual(ringlet.timeslot, timeslot)
        XCTAssertEqual(ringlet.before.executables.count, before.executables.count)
        if ringlet.before.executables.count == before.executables.count {
            XCTAssertEqual(ringlet.before.executables[0].information, before.executables[0].information)
            XCTAssertIdentical(ringlet.before.executables[0].context, before.executables[0].context)
        }
        XCTAssertEqual(ringlet.after.executables.count, after.executables.count)
        if ringlet.after.executables.count == after.executables.count {
            XCTAssertEqual(ringlet.after.executables[0].information, after.executables[0].information)
            XCTAssertIdentical(ringlet.after.executables[0].context, after.executables[0].context)
        }
        XCTAssertEqual(ringlet.transitioned, transitioned)
        compare(ringlet.preSnapshot, preSnapshot)
        compare(ringlet.postSnapshot, postSnapshot)
        XCTAssertEqual(ringlet.calls, calls)
        XCTAssertEqual(ringlet.condition, condition)
    }

    func testInitFromRinglet() {
        let rawRinglet = Ringlet(
            timeslot: timeslot,
            before: before,
            after: after,
            transitioned: transitioned,
            preSnapshot: preSnapshot,
            postSnapshot: postSnapshot,
            calls: calls,
            afterCalls: []
        )
        let ringlet = ConditionalRinglet(ringlet: rawRinglet, condition: condition)
        XCTAssertEqual(ringlet.timeslot, timeslot)
        XCTAssertEqual(ringlet.before.executables.count, before.executables.count)
        if ringlet.before.executables.count == before.executables.count {
            XCTAssertEqual(ringlet.before.executables[0].information, before.executables[0].information)
            XCTAssertIdentical(ringlet.before.executables[0].context, before.executables[0].context)
        }
        XCTAssertEqual(ringlet.after.executables.count, after.executables.count)
        if ringlet.after.executables.count == after.executables.count {
            XCTAssertEqual(ringlet.after.executables[0].information, after.executables[0].information)
            XCTAssertIdentical(ringlet.after.executables[0].context, after.executables[0].context)
        }
        XCTAssertEqual(ringlet.transitioned, transitioned)
        compare(ringlet.preSnapshot, preSnapshot)
        compare(ringlet.postSnapshot, postSnapshot)
        XCTAssertEqual(ringlet.calls, calls)
        XCTAssertEqual(ringlet.condition, condition)
    }

}
