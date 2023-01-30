import XCTest

@testable import FSM

final class RoundRobinSchedulerTests: XCTestCase {

    func testCycleTerminates() {
        let schedule = ScheduleMock()
        var scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:])
        let exitSensorName = FSMMock().exitSensor.id
        let actuator = InMemoryActuator(id: exitSensorName, initialValue: false)
        actuator.saveSnapshot(value: true)
        for _ in 0..<5 {
            scheduler.cycle()
        }
        XCTAssertTrue(scheduler.shouldTerminate)
    }

}
