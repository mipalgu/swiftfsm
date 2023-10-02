import FSM
import KripkeStructure
import XCTest

@testable import Verification

final class TimeAwareRingletTests: XCTestCase {

    func test_computesAllRingletsforSimpleTimeFSM() throws {
        func ringlets(startingTime: Duration) -> [ConditionalRinglet] {
            let model = TimeConditionalMachine()
            let (executable, contextFactory) = model.initial(
                actuators: [],
                externalVariables: [],
                globalVariables: [],
                sensors: []
            )
            let info = FSMInformation(fsm: model)
            let context = contextFactory(nil)
            let pool = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
            let timeslot = Timeslot(
                executables: [info.id],
                callChain: CallChain(root: info.id, calls: []),
                startingTime: 0,
                duration: 30,
                cyclesExecuted: 0
            )
            executable.next(context: context) // Move the fsm past the initial pseudo state.
            executable.takeSnapshot(context: context) // Set environment variables.
            // Check that the TimeAwareRinglets actually set a forced running time.
            context.duration = Duration.seconds(UInt.max)
            let results = TimeAwareRinglets(
                fsm: info,
                pool: pool,
                timeslot: timeslot,
                startingTime: startingTime
            )
            return results.ringlets
        }
        func expected(startingTime: Duration) -> [ConditionalRinglet] {
            let gaps: [Duration] = [
                .milliseconds(5) + .nanoseconds(1),
                .milliseconds(15) + .nanoseconds(1),
                .milliseconds(20) + .nanoseconds(1),
                .milliseconds(25) + .nanoseconds(1)
            ]
            let times: [Duration] = [startingTime] + gaps.filter { $0 > startingTime }
            return times.map { time in
                let model = TimeConditionalMachine()
                let (executable, contextFactory) = model.initial(
                    actuators: [],
                    externalVariables: [],
                    globalVariables: [],
                    sensors: []
                )
                let info = FSMInformation(fsm: model)
                let context = contextFactory(nil)
                let pool = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
                let timeslot = Timeslot(
                    executables: [info.id],
                    callChain: CallChain(root: info.id, calls: []),
                    startingTime: 0,
                    duration: 30,
                    cyclesExecuted: 0
                )
                executable.next(context: context) // Move the fsm past the initial pseudo state.
                executable.takeSnapshot(context: context) // Set environment variables.
                let beforePool = pool.cloned
                context.duration = time
                executable.next(context: context)
                let condition: Constraint<UInt>
                switch time.timeValue {
                case 0...(Duration.milliseconds(5).timeValue):
                    condition = .lessThanEqual(value: Duration.milliseconds(5).timeValue)
                case (Duration.milliseconds(5).timeValue + 1)...(Duration.milliseconds(15).timeValue):
                    condition = .and(
                        lhs: .greaterThan(value: Duration.milliseconds(5).timeValue),
                        rhs: .lessThanEqual(value: Duration.milliseconds(15).timeValue)
                    )
                case (Duration.milliseconds(15).timeValue + 1)...(Duration.milliseconds(20).timeValue):
                    condition = .and(
                        lhs: .greaterThan(value: Duration.milliseconds(15).timeValue),
                        rhs: .lessThanEqual(value: Duration.milliseconds(20).timeValue)
                    )
                case (Duration.milliseconds(20).timeValue + 1)...(Duration.milliseconds(25).timeValue):
                    condition = .and(
                        lhs: .greaterThan(value: Duration.milliseconds(20).timeValue),
                        rhs: .lessThanEqual(value: Duration.milliseconds(25).timeValue)
                    )
                default:
                    condition = .greaterThan(value: Duration.milliseconds(25).timeValue)
                }
                let beforeContext = beforePool.context(info.id)
                executable.setup(context: context)
                defer { executable.tearDown(context: context) }
                executable.setup(context: beforeContext)
                defer { executable.tearDown(context: beforeContext) }
                let preSnapshot = KripkeStatePropertyList(beforeContext)
                let postSnapshot = KripkeStatePropertyList(context)
                return ConditionalRinglet(
                    timeslot: timeslot,
                    before: beforePool,
                    after: pool,
                    transitioned: time > .milliseconds(20),
                    preSnapshot: preSnapshot,
                    postSnapshot: postSnapshot,
                    calls: [],
                    condition: condition
                )
            }
        }
        func test(startingTime: Duration) {
            let results = ringlets(startingTime: startingTime)
            let expected = expected(startingTime: startingTime)
            XCTAssertEqual(results, expected)
            if results != expected {
                XCTAssertEqual(results.count, expected.count)
                XCTAssertEqual(results.map(\.condition), expected.map(\.condition))
                for (result, expected) in zip(results, expected) {
                    XCTAssertEqual(result.preSnapshot, expected.preSnapshot)
                    XCTAssertEqual(result.postSnapshot, expected.postSnapshot)
                    XCTAssertEqual(result.calls, expected.calls)
                    XCTAssertEqual(result.condition, expected.condition)
                }
            }
        }
        test(startingTime: .zero)
        test(startingTime: .milliseconds(6))
        test(startingTime: .milliseconds(16))
        test(startingTime: .milliseconds(21))
        test(startingTime: .milliseconds(26))
    }

}
