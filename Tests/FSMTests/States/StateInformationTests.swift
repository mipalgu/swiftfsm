import Foundation
import XCTest

@testable import FSM

final class StateInformationTests: XCTestCase {

    func testInit() {
        let id = 2
        let name = "Something"
        let info = StateInformation(id: id, name: name)
        XCTAssertEqual(info.id, id)
        XCTAssertEqual(info.name, name)
    }

    func testNameInit() {
        IDRegistrar.removeAll()
        let name = "SomeName"
        let id = IDRegistrar.id(of: name)
        let info = StateInformation(name: name)
        XCTAssertEqual(info.id, id)
        XCTAssertEqual(info.name, name)
    }

    func testGettersAndSetters() {
        let id = 1
        let name = "name"
        var info = StateInformation(id: id, name: name)
        XCTAssertEqual(info.id, id)
        XCTAssertEqual(info.name, name)
        let newID = 3
        let newName = "newName"
        info.id = newID
        XCTAssertEqual(info.id, newID)
        XCTAssertEqual(info.name, name)
        info.id = id
        XCTAssertEqual(info.id, id)
        XCTAssertEqual(info.name, name)
        info.name = newName
        XCTAssertEqual(info.id, id)
        XCTAssertEqual(info.name, newName)
    }

    func testEquality() {
        let info = StateInformation(id: 0, name: "name")
        var info2 = info
        XCTAssertEqual(info, info2)
        XCTAssertEqual(info2, info)
        info2.id = 1
        XCTAssertNotEqual(info, info2)
        XCTAssertNotEqual(info2, info)
        info2.id = info.id
        XCTAssertEqual(info, info2)
        XCTAssertEqual(info2, info)
        info2.name = "newName"
        XCTAssertNotEqual(info, info2)
        XCTAssertNotEqual(info2, info)
    }

    func testHashable() {
        let info = StateInformation(id: 123, name: "name")
        let info2 = StateInformation(id: 0, name: "name")
        let info3 = StateInformation(id: 123, name: "newName")
        var collection = Set<StateInformation>()
        XCTAssertFalse(collection.contains(info))
        collection.insert(info)
        XCTAssertTrue(collection.contains(info))
        XCTAssertFalse(collection.contains(info2))
        XCTAssertFalse(collection.contains(info3))
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let info = StateInformation(id: 213, name: "name")
        let info2 = try decoder.decode(StateInformation.self, from: encoder.encode(info))
        XCTAssertEqual(info, info2)
    }

}
