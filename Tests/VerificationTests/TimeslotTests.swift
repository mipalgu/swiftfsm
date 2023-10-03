import Foundation
import FSM
import XCTest

@testable import Verification

final class TimeslotTests: XCTestCase {

    let executables: Set<Int> = [0, 1, 2, 3]

    let callChain = CallChain(
        root: 0,
        calls: [
            Call(
                caller: FSMInformation(id: 0, name: "exe0", dependencies: []),
                callee: FSMInformation(id: 1, name: "exe1", dependencies: []),
                parameters: [:],
                method: .synchronous
            ),
            Call(
                caller: FSMInformation(id: 1, name: "exe1", dependencies: []),
                callee: FSMInformation(id: 2, name: "exe2", dependencies: []),
                parameters: [:],
                method: .synchronous
            )
        ]
    )

    let externalDependencies: [ExecutableDependency] = [.submachine(id: 10)]

    let startingTime: Duration = .nanoseconds(34)

    let duration: Duration = .nanoseconds(12)

    let cyclesExecuted: UInt = 5

    var timeslot = Timeslot(
        executables: [],
        callChain: CallChain(root: 0, calls: []),
        externalDependencies: [],
        startingTime: .zero,
        duration: .zero,
        cyclesExecuted: 0
    )

    override func setUp() {
        timeslot = Timeslot(
            executables: executables,
            callChain: callChain,
            externalDependencies: externalDependencies,
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: cyclesExecuted
        )
    }

    func testInit() {
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(externalDependencies, timeslot.externalDependencies)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
    }

    func testGettersAndSetters() {
        let original = timeslot
        let newExecutables: Set<Int> = [4, 5, 6]
        timeslot.executables = newExecutables
        XCTAssertEqual(newExecutables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(externalDependencies, timeslot.externalDependencies)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.executables = executables
        XCTAssertEqual(timeslot, original)
        let newCalls = callChain.calls + [
            Call(
                caller: FSMInformation(id: 2, name: "exe2", dependencies: []),
                callee: FSMInformation(id: 3, name: "exe3", dependencies: []),
                parameters: [:],
                method: .synchronous
            )
        ]
        let newCallChain = CallChain(root: 0, calls: newCalls)
        timeslot.callChain = newCallChain
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(newCallChain, timeslot.callChain)
        XCTAssertEqual(externalDependencies, timeslot.externalDependencies)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.callChain = callChain
        XCTAssertEqual(timeslot, original)
        let newExternalDependencies: [ExecutableDependency] = [.sync(id: 200)]
        timeslot.externalDependencies = newExternalDependencies
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(newExternalDependencies, timeslot.externalDependencies)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.externalDependencies = externalDependencies
        XCTAssertEqual(timeslot, original)
        let newStartingTime: Duration = .milliseconds(123)
        timeslot.startingTime = newStartingTime
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(newStartingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.startingTime = startingTime
        XCTAssertEqual(timeslot, original)
        let newDuration: Duration = .milliseconds(98)
        timeslot.duration = newDuration
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(newDuration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.duration = duration
        XCTAssertEqual(timeslot, original)
        let newCyclesExecuted: UInt = 10
        timeslot.cyclesExecuted = newCyclesExecuted
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(callChain, timeslot.callChain)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(newCyclesExecuted, timeslot.cyclesExecuted)
        timeslot.cyclesExecuted = cyclesExecuted
        XCTAssertEqual(timeslot, original)
    }

    func testEquality() {
        let original = timeslot
        XCTAssertEqual(timeslot, original)
        let newExecutables: Set<Int> = [4, 5, 6]
        timeslot.executables = newExecutables
        XCTAssertNotEqual(timeslot, original)
        timeslot.executables = executables
        XCTAssertEqual(timeslot, original)
        let newCalls = callChain.calls + [
            Call(
                caller: FSMInformation(id: 2, name: "exe2", dependencies: []),
                callee: FSMInformation(id: 3, name: "exe3", dependencies: []),
                parameters: [:],
                method: .synchronous
            )
        ]
        let newCallChain = CallChain(root: 0, calls: newCalls)
        timeslot.callChain = newCallChain
        XCTAssertNotEqual(timeslot, original)
        timeslot.callChain = callChain
        XCTAssertEqual(timeslot, original)
        let newExternalDependencies: [ExecutableDependency] = [.sync(id: 200)]
        timeslot.externalDependencies = newExternalDependencies
        XCTAssertNotEqual(timeslot, original)
        timeslot.externalDependencies = externalDependencies
        XCTAssertEqual(timeslot, original)
        let newStartingTime: Duration = .milliseconds(123)
        timeslot.startingTime = newStartingTime
        XCTAssertNotEqual(timeslot, original)
        timeslot.startingTime = startingTime
        XCTAssertEqual(timeslot, original)
        let newDuration: Duration = .milliseconds(98)
        timeslot.duration = newDuration
        XCTAssertNotEqual(timeslot, original)
        timeslot.duration = duration
        XCTAssertEqual(timeslot, original)
        let newCyclesExecuted: UInt = 10
        timeslot.cyclesExecuted = newCyclesExecuted
        XCTAssertNotEqual(timeslot, original)
        timeslot.cyclesExecuted = cyclesExecuted
        XCTAssertEqual(timeslot, original)
    }

    func testHashable() {
        let original = timeslot
        var collection: Set<Timeslot> = []
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        collection.insert(original)
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newExecutables: Set<Int> = [4, 5, 6]
        timeslot.executables = newExecutables
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.executables = executables
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newCalls = callChain.calls + [
            Call(
                caller: FSMInformation(id: 2, name: "exe2", dependencies: []),
                callee: FSMInformation(id: 3, name: "exe3", dependencies: []),
                parameters: [:],
                method: .synchronous
            )
        ]
        let newCallChain = CallChain(root: 0, calls: newCalls)
        timeslot.callChain = newCallChain
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.callChain = callChain
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newExternalDependencies: [ExecutableDependency] = [.sync(id: 200)]
        timeslot.externalDependencies = newExternalDependencies
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.externalDependencies = externalDependencies
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newStartingTime: Duration = .milliseconds(123)
        timeslot.startingTime = newStartingTime
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.startingTime = startingTime
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newDuration: Duration = .milliseconds(98)
        timeslot.duration = newDuration
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.duration = duration
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newCyclesExecuted: UInt = 10
        timeslot.cyclesExecuted = newCyclesExecuted
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.cyclesExecuted = cyclesExecuted
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
    }

    func testTimeRangeComputesCorrectRange() {
        let range: ClosedRange<UInt> = timeslot.timeRange
        XCTAssertEqual(startingTime.timeValue, range.lowerBound)
        XCTAssertEqual((startingTime + duration).timeValue, range.upperBound)
    }

    func testAfterExecutingTimeUntilForTimeLargerThanDuration() {
        XCTAssertEqual(
            .nanoseconds(4),
            timeslot.afterExecutingTimeUntil(time: .nanoseconds(50), cycleLength: .nanoseconds(100))
        )
    }

    func testAfterExecutingTimeUntilForTimeSmallerThanStartingTime() {
        XCTAssertEqual(
            .nanoseconds(16),
            timeslot.afterExecutingTimeUntil(time: .nanoseconds(12), cycleLength: .nanoseconds(50))
        )
    }

    func testAfterExecutingTimeUntilForTimeForSameTimeIsZero() {
        XCTAssertEqual(
            .zero,
            timeslot.afterExecutingTimeUntil(time: startingTime + duration, cycleLength: .nanoseconds(50))
        )
    }

    func testAfterExecutingTimeUntilForTimeslotLargerThanDuration() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: .nanoseconds(50),
            duration: .nanoseconds(12),
            cyclesExecuted: 0
        )
        XCTAssertEqual(
            .nanoseconds(4),
            timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: .nanoseconds(100))
        )
    }

    func testAfterExecutingTimeUntilForTimeslotSmallerThanStartingTime() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: .nanoseconds(12),
            duration: .nanoseconds(12),
            cyclesExecuted: 0
        )
        XCTAssertEqual(
            .nanoseconds(16),
            timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: .nanoseconds(50))
        )
    }

    func testAfterExecutingTimeUntilForTimeslotSameTimeIsZero() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime + duration,
            duration: .nanoseconds(12),
            cyclesExecuted: 0
        )
        XCTAssertEqual(
            .zero,
            timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: .nanoseconds(50))
        )
    }

    func testSameTimeslotsOverlap() {
        XCTAssertTrue(timeslot.overlaps(with: timeslot), "Expected the same timeslot to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingDuringExecution() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime + .nanoseconds(1),
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingAndEndingDuringExecution() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime + .nanoseconds(1),
            duration: duration - .nanoseconds(2),
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingBeforeExecution() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime - .nanoseconds(1),
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingBeforeExecutionAndFinishingAfterExecution() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime - .nanoseconds(1),
            duration: duration + .nanoseconds(2),
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotsOverlapWhenStartingAtFinishingTime() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime + duration,
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotDoNotOverlapWhenDisjoint() {
        let other = Timeslot(
            executables: [],
            callChain: CallChain(root: 0, calls: []),
            externalDependencies: [],
            startingTime: startingTime + duration + .nanoseconds(1),
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertFalse(timeslot.overlaps(with: other), "Expected timeslots to not overlap.")
        XCTAssertFalse(other.overlaps(with: timeslot), "Expected timeslots to not overlap.")
    }

}
