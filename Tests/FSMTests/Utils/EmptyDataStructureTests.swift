import Foundation
import XCTest

@testable import FSM

final class EmptyDataStructureTests: XCTestCase {

    func testInit() {
        _ = EmptyDataStructure()
    }

    func testEquality() {
        let empty1 = EmptyDataStructure()
        let empty2 = EmptyDataStructure()
        XCTAssertEqual(empty1, empty2)
    }

    func testHashable() {
        let empty = EmptyDataStructure()
        var collection = Set<EmptyDataStructure>()
        XCTAssertFalse(collection.contains(empty))
        collection.insert(empty)
        XCTAssertTrue(collection.contains(empty))
        collection.remove(empty)
        XCTAssertFalse(collection.contains(empty))
    }

    func testCodable() throws {
        let empty = EmptyDataStructure()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let result = try decoder.decode(EmptyDataStructure.self, from: encoder.encode(empty))
        XCTAssertEqual(empty, result)
    }

}
