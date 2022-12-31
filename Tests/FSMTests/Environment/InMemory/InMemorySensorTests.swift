import XCTest

@testable import FSM

final class InMemorySensorTests: XCTestCase {

    let id = "inMemorySensor"

    var sensor: InMemorySensor<Bool>!

    override func setUp() {
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.saveSnapshot()
        sensor = InMemorySensor(id: id, initialValue: false)
    }

    func testInit() {
        let sensor = InMemoryActuator(id: id, initialValue: false)
        XCTAssertEqual(sensor.id, id)
        XCTAssertEqual(sensor.value, false)
        let sensor2 = InMemoryActuator(id: id, initialValue: true)
        XCTAssertEqual(sensor2.id, id)
        XCTAssertEqual(sensor2.value, true)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
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

    func testTakeSnapshotPerformance_1() {
        measure {
            sensor.takeSnapshot()
        }
    }

    func testTakeSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                sensor.takeSnapshot()
            }
        }
    }

}
