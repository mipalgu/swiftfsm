import Foundation
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

    func testEquality() {
        let id1 = "id1"
        let id2 = "id2"
        let globalVariable1 = InMemoryGlobalVariable(id: id1, initialValue: false)
        let globalVariable2 = InMemoryGlobalVariable(id: id1, initialValue: true)
        let globalVariable3 = InMemoryGlobalVariable(id: id2, initialValue: false)
        let globalVariable4 = InMemoryGlobalVariable(id: id2, initialValue: true)
        XCTAssertEqual(globalVariable1, globalVariable1)
        XCTAssertEqual(globalVariable2, globalVariable2)
        XCTAssertEqual(globalVariable3, globalVariable3)
        XCTAssertEqual(globalVariable4, globalVariable4)
        XCTAssertNotEqual(globalVariable1, globalVariable2)
        XCTAssertNotEqual(globalVariable2, globalVariable1)
        XCTAssertNotEqual(globalVariable1, globalVariable3)
        XCTAssertNotEqual(globalVariable3, globalVariable1)
        XCTAssertNotEqual(globalVariable1, globalVariable4)
        XCTAssertNotEqual(globalVariable4, globalVariable1)
        XCTAssertNotEqual(globalVariable2, globalVariable3)
        XCTAssertNotEqual(globalVariable3, globalVariable2)
        XCTAssertNotEqual(globalVariable2, globalVariable4)
        XCTAssertNotEqual(globalVariable4, globalVariable2)
        XCTAssertNotEqual(globalVariable3, globalVariable4)
        XCTAssertNotEqual(globalVariable4, globalVariable3)
    }

    func testHashable() {
        let id1 = "id1"
        let id2 = "id2"
        let globalVariable1 = InMemoryGlobalVariable(id: id1, initialValue: false)
        let globalVariable2 = InMemoryGlobalVariable(id: id1, initialValue: true)
        let globalVariable3 = InMemoryGlobalVariable(id: id2, initialValue: false)
        let globalVariable4 = InMemoryGlobalVariable(id: id2, initialValue: true)
        var collection = Set<InMemoryGlobalVariable<Bool>>()
        collection.insert(globalVariable1)
        XCTAssertTrue(collection.contains(globalVariable1))
        XCTAssertFalse(collection.contains(globalVariable2))
        XCTAssertFalse(collection.contains(globalVariable3))
        XCTAssertFalse(collection.contains(globalVariable4))
        collection.removeAll()
        collection.insert(globalVariable2)
        XCTAssertTrue(collection.contains(globalVariable2))
        XCTAssertFalse(collection.contains(globalVariable1))
        XCTAssertFalse(collection.contains(globalVariable3))
        XCTAssertFalse(collection.contains(globalVariable4))
        collection.removeAll()
        collection.insert(globalVariable3)
        XCTAssertTrue(collection.contains(globalVariable3))
        XCTAssertFalse(collection.contains(globalVariable1))
        XCTAssertFalse(collection.contains(globalVariable2))
        XCTAssertFalse(collection.contains(globalVariable4))
        collection.removeAll()
        collection.insert(globalVariable4)
        XCTAssertTrue(collection.contains(globalVariable4))
        XCTAssertFalse(collection.contains(globalVariable1))
        XCTAssertFalse(collection.contains(globalVariable2))
        XCTAssertFalse(collection.contains(globalVariable3))
    }

    func testCodable() throws {
        let id1 = "id1"
        let id2 = "id2"
        let globalVariable1 = InMemoryGlobalVariable(id: id1, initialValue: false)
        let globalVariable2 = InMemoryGlobalVariable(id: id1, initialValue: true)
        let globalVariable3 = InMemoryGlobalVariable(id: id2, initialValue: false)
        let globalVariable4 = InMemoryGlobalVariable(id: id2, initialValue: true)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let result1 = try decoder.decode(
            InMemoryGlobalVariable<Bool>.self,
            from: encoder.encode(globalVariable1)
        )
        XCTAssertEqual(result1, globalVariable1)
        let result2 = try decoder.decode(
            InMemoryGlobalVariable<Bool>.self,
            from: encoder.encode(globalVariable2)
        )
        XCTAssertEqual(result2, globalVariable2)
        let result3 = try decoder.decode(
            InMemoryGlobalVariable<Bool>.self,
            from: encoder.encode(globalVariable3)
        )
        XCTAssertEqual(result3, globalVariable3)
        let result4 = try decoder.decode(
            InMemoryGlobalVariable<Bool>.self,
            from: encoder.encode(globalVariable4)
        )
        XCTAssertEqual(result4, globalVariable4)
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
