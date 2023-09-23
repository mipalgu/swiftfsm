import Foundation
import XCTest

@testable import Verification

final class TimeslotTests: XCTestCase {

    let executables: Set<Int> = [1, 2, 3]

    let startingTime: UInt = 34

    let duration: UInt = 12

    let cyclesExecuted: UInt = 5

    var timeslot = Timeslot(
        executables: [],
        startingTime: 0,
        duration: 0,
        cyclesExecuted: 0
    )

    override func setUp() {
        timeslot = Timeslot(
            executables: executables,
            startingTime: startingTime,
            duration: duration,
            cyclesExecuted: cyclesExecuted
        )
    }

    func testInit() {
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
    }

    func testGettersAndSetters() {
        let original = timeslot
        let newExecutables: Set<Int> = [4, 5, 6]
        timeslot.executables = newExecutables
        XCTAssertEqual(newExecutables, timeslot.executables)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.executables = executables
        XCTAssertEqual(timeslot, original)
        let newStartingTime: UInt = 123
        timeslot.startingTime = newStartingTime
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(newStartingTime, timeslot.startingTime)
        XCTAssertEqual(duration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.startingTime = startingTime
        XCTAssertEqual(timeslot, original)
        let newDuration: UInt = 98
        timeslot.duration = newDuration
        XCTAssertEqual(executables, timeslot.executables)
        XCTAssertEqual(startingTime, timeslot.startingTime)
        XCTAssertEqual(newDuration, timeslot.duration)
        XCTAssertEqual(cyclesExecuted, timeslot.cyclesExecuted)
        timeslot.duration = duration
        XCTAssertEqual(timeslot, original)
        let newCyclesExecuted: UInt = 10
        timeslot.cyclesExecuted = newCyclesExecuted
        XCTAssertEqual(executables, timeslot.executables)
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
        let newStartingTime: UInt = 123
        timeslot.startingTime = newStartingTime
        XCTAssertNotEqual(timeslot, original)
        timeslot.startingTime = startingTime
        XCTAssertEqual(timeslot, original)
        let newDuration: UInt = 98
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
        let newStartingTime: UInt = 123
        timeslot.startingTime = newStartingTime
        XCTAssertFalse(collection.contains(timeslot), "Expected timeslot to not exist in collection")
        timeslot.startingTime = startingTime
        XCTAssertTrue(collection.contains(timeslot), "Expected timeslot to exist in collection")
        let newDuration: UInt = 98
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

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(timeslot)
        let decoded = try decoder.decode(Timeslot.self, from: data)
        XCTAssertEqual(timeslot, decoded)
    }

    func testTimeRangeComputesCorrectRange() {
        let range: ClosedRange<UInt> = timeslot.timeRange
        XCTAssertEqual(startingTime, range.lowerBound)
        XCTAssertEqual(startingTime + duration, range.upperBound)
    }

    func testAfterExecutingTimeUntilForTimeLargerThanDuration() {
        XCTAssertEqual(4, timeslot.afterExecutingTimeUntil(time: 50, cycleLength: 100))
    }

    func testAfterExecutingTimeUntilForTimeSmallerThanStartingTime() {
        XCTAssertEqual(16, timeslot.afterExecutingTimeUntil(time: 12, cycleLength: 50))
    }

    func testAfterExecutingTimeUntilForTimeForSameTimeIsZero() {
        XCTAssertEqual(0, timeslot.afterExecutingTimeUntil(time: startingTime + duration, cycleLength: 50))
    }

    func testAfterExecutingTimeUntilForTimeslotLargerThanDuration() {
        let other = Timeslot(executables: [], startingTime: 50, duration: 12, cyclesExecuted: 0)
        XCTAssertEqual(4, timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: 100))
    }

    func testAfterExecutingTimeUntilForTimeslotSmallerThanStartingTime() {
        let other = Timeslot(executables: [], startingTime: 12, duration: 12, cyclesExecuted: 0)
        XCTAssertEqual(16, timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: 50))
    }

    func testAfterExecutingTimeUntilForTimeslotSameTimeIsZero() {
        let other = Timeslot(
            executables: [],
            startingTime: startingTime + duration,
            duration: 12,
            cyclesExecuted: 0
        )
        XCTAssertEqual(0, timeslot.afterExecutingTimeUntil(timeslot: other, cycleLength: 50))
    }

    func testSameTimeslotsOverlap() {
        XCTAssertTrue(timeslot.overlaps(with: timeslot), "Expected the same timeslot to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingDuringExecution() {
        let other = Timeslot(
            executables: [],
            startingTime: startingTime + 1,
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingAndEndingDuringExecution() {
        let other = Timeslot(
            executables: [],
            startingTime: startingTime + 1,
            duration: duration - 2,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingBeforeExecution() {
        let other = Timeslot(
            executables: [],
            startingTime: startingTime - 1,
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotOverlapsWithTimeslotStartingBeforeExecutionAndFinishingAfterExecution() {
        let other = Timeslot(
            executables: [],
            startingTime: startingTime - 1,
            duration: duration + 2,
            cyclesExecuted: 0
        )
        XCTAssertTrue(timeslot.overlaps(with: other), "Expected timeslots to overlap.")
        XCTAssertTrue(other.overlaps(with: timeslot), "Expected timeslots to overlap.")
    }

    func testTimeslotsOverlapWhenStartingAtFinishingTime() {
        let other = Timeslot(
            executables: [],
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
            startingTime: startingTime + duration + 1,
            duration: duration,
            cyclesExecuted: 0
        )
        XCTAssertFalse(timeslot.overlaps(with: other), "Expected timeslots to not overlap.")
        XCTAssertFalse(other.overlaps(with: timeslot), "Expected timeslots to not overlap.")
    }

}
