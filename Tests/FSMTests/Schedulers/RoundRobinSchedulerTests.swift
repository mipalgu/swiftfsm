import InMemoryVariables
import Mocks
import Model
import XCTest

@testable import FSM

final class RoundRobinSchedulerTests: XCTestCase {

    var contexts: [SchedulerContextProtocol] = []

    var data: [ErasedFiniteStateMachineData] = []

    var schedule = ScheduleMock()

    override func setUp() {
        schedule = ScheduleMock()
        let fsms = schedule.arrangement.fsms
        contexts.removeAll(keepingCapacity: true)
        data.removeAll(keepingCapacity: true)
        contexts.reserveCapacity(fsms.count)
        data.reserveCapacity(fsms.count)
    }

    func doTest(
        testFunc: (UnsafeMutablePointer<SchedulerContextProtocol>, UnsafeMutablePointer<ErasedFiniteStateMachineData>) -> Void
    ) {
        contexts.withContiguousMutableStorageIfAvailable { contextPtr in
            data.withContiguousMutableStorageIfAvailable { dataPtr in
                testFunc(contextPtr.baseAddress!, dataPtr.baseAddress!)
            }
        }
    }

    func testInit() {
        doTest {
            let scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:], contexts: $0, data: $1)
            XCTAssertFalse(scheduler.shouldTerminate)
        }
    }

    func testCycleTerminates() {
        doTest {
            var scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:], contexts: $0, data: $1)
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
    }

}
