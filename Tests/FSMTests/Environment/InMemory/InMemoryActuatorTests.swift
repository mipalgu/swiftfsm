import XCTest

@testable import FSM

final class InMemoryActuatorTests: XCTestCase {

    let id = "inMemoryActuator"

    var actuator: InMemoryActuator<Bool>!

    override func setUp() {
        actuator = InMemoryActuator(id: id, initialValue: false)
    }

    func testInit() {
        let actuator = InMemoryActuator<Bool>(id: id, initialValue: false)
        XCTAssertEqual(actuator.id, id)
        XCTAssertEqual(actuator.initialValue, false)
        let actuator2 = InMemoryActuator<Bool>(id: id, initialValue: true)
        XCTAssertEqual(actuator2.id, id)
        XCTAssertEqual(actuator2.initialValue, true)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        let sensor = InMemorySensor(id: id, initialValue: false)
        actuator.saveSnapshot(value: false)
        XCTAssertEqual(sensor.takeSnapshot(), false)
        actuator.saveSnapshot(value: true)
        XCTAssertEqual(sensor.takeSnapshot(), true)
    }

    func testSaveSnapshotPerformance_1() {
        measure {
            actuator.saveSnapshot(value: true)
        }
    }

    func testSaveSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                actuator.saveSnapshot(value: true)
            }
        }
    }

}
