import XCTest

@testable import FSM

final class InMemoryExternalVariableTests: XCTestCase {

    let id = "inMemoryExternalVariable"

    var externalVariable: InMemoryExternalVariable<Bool>!

    override func setUp() {
        var actuator = InMemoryActuator(id: id, initialValue: false)
        actuator.saveSnapshot()
        externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
    }

    func testInit() {
        let externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
        XCTAssertEqual(externalVariable.id, id)
        XCTAssertEqual(externalVariable.value, false)
        let externalVariable2 = InMemoryExternalVariable(id: id, initialValue: true)
        XCTAssertEqual(externalVariable2.id, id)
        XCTAssertEqual(externalVariable2.value, true)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        var externalVariable = InMemoryExternalVariable(id: id, initialValue: false)
        var externalVariable2 = InMemoryExternalVariable(id: id, initialValue: false)
        externalVariable.saveSnapshot()
        externalVariable2.takeSnapshot()
        XCTAssertEqual(externalVariable.value, externalVariable2.value)
        XCTAssertEqual(externalVariable.value, false)
        externalVariable.value = true
        externalVariable.saveSnapshot()
        externalVariable2.takeSnapshot()
        XCTAssertEqual(externalVariable.value, externalVariable2.value)
        XCTAssertEqual(externalVariable.value, true)
        externalVariable2.value = false
        externalVariable2.saveSnapshot()
        externalVariable.takeSnapshot()
        XCTAssertEqual(externalVariable.value, externalVariable2.value)
        XCTAssertEqual(externalVariable.value, false)
        externalVariable2.value = true
        externalVariable2.saveSnapshot()
        externalVariable.takeSnapshot()
        XCTAssertEqual(externalVariable.value, externalVariable2.value)
        XCTAssertEqual(externalVariable.value, true)
    }

    func testSaveSnapshotPerformance_1() {
        externalVariable.value = true
        measure {
            externalVariable.saveSnapshot()
        }
    }

    func testSaveSnapshotPerformance_10() {
        externalVariable.value = true
        measure {
            for _ in 0..<10 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100() {
        externalVariable.value = true
        measure {
            for _ in 0..<100 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1000() {
        externalVariable.value = true
        measure {
            for _ in 0..<1000 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_10_000() {
        externalVariable.value = true
        measure {
            for _ in 0..<10000 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_100_000() {
        externalVariable.value = true
        measure {
            for _ in 0..<100_000 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testSaveSnapshotPerformance_1_000_000() {
        externalVariable.value = true
        measure {
            for _ in 0..<1_000_000 {
                externalVariable.saveSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1() {
        measure {
            externalVariable.takeSnapshot()
        }
    }

    func testTakeSnapshotPerformance_10() {
        measure {
            for _ in 0..<10 {
                externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100() {
        measure {
            for _ in 0..<100 {
                externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                externalVariable.takeSnapshot()
            }
        }
    }

    func testTakeSnapshotPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                externalVariable.takeSnapshot()
            }
        }
    }

}
