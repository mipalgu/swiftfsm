import XCTest

@testable import FSM

final class InMemoryActuatorTests: XCTestCase {

    func testInit() {
        let id = "inMemoryActuator"
        let initialValue = false
        let actuator = InMemoryActuator(id: id, initialValue: initialValue)
        XCTAssertEqual(actuator.id, id)
        XCTAssertEqual(actuator.value, initialValue)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
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

    func testSaveSnapshotPerformance_10() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<10 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<100 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1000() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<1000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_10_000() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<10000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100_000() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<100_000 {
                actuator.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1_000_000() {
        let id = "inMemoryActuator"
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.value = true
        measure {
            for _ in 0..<1_000_000 {
                actuator.saveSnapshot()
            }
        }
    }

}
