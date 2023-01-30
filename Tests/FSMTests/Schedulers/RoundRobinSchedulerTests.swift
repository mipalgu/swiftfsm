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
        let exitSensorName = FSMMock().exitSensor.id
        let actuator = InMemoryActuator(id: exitSensorName, initialValue: false)
        actuator.saveSnapshot(value: false)
        for _ in 0..<60 {
            XCTAssertFalse(scheduler.shouldTerminate)
            scheduler.cycle()
        }
        actuator.saveSnapshot(value: true)
        for _ in 0..<5 {
            scheduler.cycle()
        }
        XCTAssertTrue(scheduler.shouldTerminate)
    }

}
