import InMemoryVariables
import Mocks
import Model
import XCTest

@testable import FSM

final class RoundRobinSchedulerTests: XCTestCase {

    func testInit() {
        let schedule = ScheduleMock()
        let scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:])
        XCTAssertFalse(scheduler.shouldTerminate)
    }

    func testCycleTerminates() {
        let schedule = ScheduleMock()
        var scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:])
        let exitSensorName = ArrangementMock().exitSensor.id
        let actuator = InMemoryActuator(id: exitSensorName, initialValue: false)
        actuator.saveSnapshot(value: false)
        for i in 0..<60 {
            XCTAssertFalse(scheduler.shouldTerminate, "Should terminate is true on cycle \(i).")
            scheduler.cycle()
        }
        actuator.saveSnapshot(value: true)
        scheduler.cycle()
        scheduler.cycle()
        XCTAssertTrue(scheduler.shouldTerminate)
    }

    func testCyclePerformance10() {
        let schedule = RoundRobinScheduler(schedule: ArrangementMock().defaultSchedule, parameters: [:])
        measure {
            var schedule = schedule
            for _ in 0..<10 {
                schedule.cycle()
            }
        }
    }

    func testCyclePerformance100() {
        let schedule = RoundRobinScheduler(schedule: ArrangementMock().defaultSchedule, parameters: [:])
        measure {
            var schedule = schedule
            for _ in 0..<100 {
                schedule.cycle()
            }
        }
    }

    func testCyclePerformance1000() {
        let schedule = RoundRobinScheduler(schedule: ArrangementMock().defaultSchedule, parameters: [:])
        measure {
            var schedule = schedule
            for _ in 0..<1000 {
                schedule.cycle()
            }
        }
    }

    func testCyclePerformance10_000() {
        let schedule = RoundRobinScheduler(schedule: ArrangementMock().defaultSchedule, parameters: [:])
        measure {
            var schedule = schedule
            for _ in 0..<10_000 {
                schedule.cycle()
            }
        }
    }

}
