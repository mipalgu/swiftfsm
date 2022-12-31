import XCTest

@testable import FSM

final class InMemoryGlobalVariableTests: XCTestCase {

    let id = "inMemoryGlobalVariable"

    var globalVariable: InMemoryGlobalVariable<Bool>!

    override func setUp() {
        globalVariable = InMemoryGlobalVariable(id: id, initialValue: false)
        globalVariable.value = false
    }

    func testInit() {
        let id1 = "InMemoryGlobalVariableTest.testInit(false)"
        let globalVariable1 = InMemoryGlobalVariable(id: id1, initialValue: false)
        XCTAssertEqual(globalVariable1.id, id1)
        XCTAssertEqual(globalVariable1.value, false)
        let id2 = "InMemoryGlobalVariableTest.testInit(true)"
        let globalVariable2 = InMemoryGlobalVariable(id: id2, initialValue: true)
        XCTAssertEqual(globalVariable2.id, id2)
        XCTAssertEqual(globalVariable2.value, true)
        let globalVariable3 = InMemoryGlobalVariable(id: id, initialValue: true)
        XCTAssertEqual(globalVariable3.id, id)
        XCTAssertEqual(globalVariable3.value, false)
    }

    func testCanRetreiveValueAcrossTwoHandlers() {
        var globalVariable = InMemoryGlobalVariable(id: id, initialValue: false)
        var globalVariable2 = InMemoryGlobalVariable(id: id, initialValue: false)
        XCTAssertEqual(globalVariable.value, globalVariable2.value)
        XCTAssertEqual(globalVariable.value, false)
        globalVariable.value = true
        XCTAssertEqual(globalVariable.value, globalVariable2.value)
        XCTAssertEqual(globalVariable.value, true)
        globalVariable2.value = false
        XCTAssertEqual(globalVariable.value, globalVariable2.value)
        XCTAssertEqual(globalVariable.value, false)
        globalVariable2.value = true
        XCTAssertEqual(globalVariable.value, globalVariable2.value)
        XCTAssertEqual(globalVariable.value, true)
    }

    func testSetValuePerformance_1() {
        measure {
            globalVariable.value = true
        }
    }

    func testSetValuePerformance_10() {
        measure {
            for _ in 0..<10 {
                globalVariable.value = true
            }
        }
    }

    func testSetValuePerformance_100() {
        measure {
            for _ in 0..<100 {
                globalVariable.value = true
            }
        }
    }

    func testSetValuePerformance_1000() {
        measure {
            for _ in 0..<1000 {
                globalVariable.value = true
            }
        }
    }

    func testSetValuePerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                globalVariable.value = true
            }
        }
    }

    func testSetValuePerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                globalVariable.value = true
            }
        }
    }

    func testSetValuePerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                globalVariable.value = true
            }
        }
    }

    func testGetValuePerformance_1() {
        measure {
            _ = globalVariable.value
        }
    }

    func testGetValuePerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = globalVariable.value
            }
        }
    }

    func testGetValuePerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = globalVariable.value
            }
        }
    }

    func testGetValuePerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = globalVariable.value
            }
        }
    }

    func testGetValuePerformance_10_000() {
        measure {
            for _ in 0..<10000 {
                _ = globalVariable.value
            }
        }
    }

    func testGetValuePerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = globalVariable.value
            }
        }
    }

    func testGetValuePerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = globalVariable.value
            }
        }
    }

}
