import XCTest

@testable import FSM

final class InMemoryActuatorTests: XCTestCase {
    
    let id = "inMemoryActuator"

    var actuator: InMemoryActuator<Bool>!

    override func setUp() {
        actuator = InMemoryActuator(id: id, initialValue: false)
    }

    func testInit() {
        let actuator = InMemoryActuator(id: id, initialValue: false)
        XCTAssertEqual(actuator.id, id)
        XCTAssertEqual(actuator.value, false)
        let actuator2 = InMemoryActuator(id: id, initialValue: true)
        XCTAssertEqual(actuator2.id, id)
        XCTAssertEqual(actuator2.value, true)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        var sensor = InMemorySensor(id: id, initialValue: false)
        actuator.saveSnapshot()
        sensor.takeSnapshot()
        XCTAssertEqual(actuator.value, sensor.value)
        XCTAssertEqual(sensor.value, false)
        actuator.value = true
        actuator.saveSnapshot()
        sensor.takeSnapshot()
        XCTAssertEqual(actuator.value, sensor.value)
        XCTAssertEqual(sensor.value, true)
    }

    func testSaveSnapshotPerformance_1() {
        actuator.value = true
        measure {
            actuator.saveSnapshot()
        }
    }

    func testSaveSnapshotPerformance_10() {
        actuator.value = true
        measure {
            for _ in 0..<10 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100() {
        actuator.value = true
        measure {
            for _ in 0..<100 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1000() {
        actuator.value = true
        measure {
            for _ in 0..<1000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_10_000() {
        actuator.value = true
        measure {
            for _ in 0..<10000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100_000() {
        actuator.value = true
        measure {
            for _ in 0..<100_000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1_000_000() {
        actuator.value = true
        measure {
            for _ in 0..<1_000_000 {
                actuator.saveSnapshot()
            }
        }
    }

}
