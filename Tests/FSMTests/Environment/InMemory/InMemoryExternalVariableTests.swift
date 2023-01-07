import XCTest

@testable import FSM

final class InMemoryExternalVariableTests: XCTestCase {

    let id = "inMemoryExternalVariable"

    var externalVariable: InMemoryExternalVariable<Bool>!

    override func setUp() {
        let actuator = InMemoryActuator<Bool>(id: id, initialValue: false)
        actuator.saveSnapshot(value: false)
        externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
    }

    func testInit() {
        let externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
        XCTAssertEqual(externalVariable.id, id)
        let externalVariable2 = InMemoryExternalVariable(id: id, initialValue: true)
        XCTAssertEqual(externalVariable2.id, id)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        let externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
        let externalVariable2 = InMemoryExternalVariable(id: id, initialValue: false)
        externalVariable.saveSnapshot(value: false)
        XCTAssertEqual(externalVariable.takeSnapshot(), externalVariable2.takeSnapshot())
        XCTAssertEqual(externalVariable.takeSnapshot(), false)
        externalVariable.saveSnapshot(value: true)
        XCTAssertEqual(externalVariable.takeSnapshot(), externalVariable2.takeSnapshot())
        XCTAssertEqual(externalVariable.takeSnapshot(), true)
        externalVariable2.saveSnapshot(value: false)
        XCTAssertEqual(externalVariable.takeSnapshot(), externalVariable2.takeSnapshot())
        XCTAssertEqual(externalVariable.takeSnapshot(), false)
        externalVariable2.saveSnapshot(value: true)
        XCTAssertEqual(externalVariable.takeSnapshot(), externalVariable2.takeSnapshot())
        XCTAssertEqual(externalVariable.takeSnapshot(), true)
    }

    func testSaveSnapshotPerformance_1() {
        measure {
            externalVariable.saveSnapshot(value: true)
        }
    }

    func testSaveSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testSaveSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                externalVariable.saveSnapshot(value: true)
            }
        }
    }

    func testTakeSnapshotPerformance_1() {
        measure {
            _ = externalVariable.takeSnapshot()
        }
    }

    func testTakeSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = externalVariable.takeSnapshot()
            }
        }
    }

}
