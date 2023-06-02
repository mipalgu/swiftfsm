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
        let exitSensorName = FSMMock().exitSensor.id
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

}
