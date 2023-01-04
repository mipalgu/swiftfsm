import XCTest

@testable import FSM

final class InMemorySensorTests: XCTestCase {

    let id = "inMemorySensor"

    var sensor: InMemorySensor<Bool>!

    override func setUp() {
        let actuator = InMemoryActuator<Bool>(id: id)
        actuator.saveSnapshot(value: false)
        sensor = InMemorySensor(id: id, initialValue: false)
    }

    func testInit() {
        let sensor = InMemorySensor(id: id, initialValue: false)
        XCTAssertEqual(sensor.id, id)
        let sensor2 = InMemorySensor(id: id, initialValue: true)
        XCTAssertEqual(sensor2.id, id)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        let actuator = InMemoryActuator<Bool>(id: id)
        let sensor = InMemorySensor(id: id, initialValue: false)
        actuator.saveSnapshot(value: false)
        XCTAssertEqual(sensor.takeSnapshot(), false)
        actuator.saveSnapshot(value: true)
        XCTAssertEqual(sensor.takeSnapshot(), true)
    }

    func testTakeSnapshotPerformance_1() {
        measure {
            _ = sensor.takeSnapshot()
        }
    }

    func testTakeSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                _ = sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = sensor.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = sensor.takeSnapshot()
            }
        }
    }

}
