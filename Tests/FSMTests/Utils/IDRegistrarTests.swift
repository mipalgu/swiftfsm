import XCTest

@testable import FSM

final class IDRegistrarTests: XCTestCase {

    override func setUp() {
        IDRegistrar.removeAll()
    }

    func testCalculatesIdFromName() {
        let name = "some_name"
        let id = IDRegistrar.id(of: name)
        let calculatedName = IDRegistrar.name(of: id)
        XCTAssertNotNil(calculatedName)
        XCTAssertEqual(name, calculatedName)
        XCTAssertGreaterThanOrEqual(id, 0)
    }

    func testCannotCalculateNameForNonExistentID() {
        let calculatedName = IDRegistrar.name(of: -1)
        XCTAssertNil(calculatedName)
    }

    func testIDsAreDistinct() {
        let name1 = "name1"
        let name2 = "name2"
        let id1 = IDRegistrar.id(of: name1)
        let id2 = IDRegistrar.id(of: name2)
        XCTAssertNotEqual(id1, id2)
        let calculatedName1 = IDRegistrar.name(of: id1)
        let calculatedName2 = IDRegistrar.name(of: id2)
        XCTAssertNotNil(calculatedName1)
        XCTAssertEqual(name1, calculatedName1)
        XCTAssertNotNil(calculatedName2)
        XCTAssertEqual(name2, calculatedName2)
    }

    func testRemoveAllInvalidatesIDs() {
        let name1 = "name1"
        let name2 = "name2"
        let id1 = IDRegistrar.id(of: name1)
        let id2 = IDRegistrar.id(of: name2)
        XCTAssertNotEqual(id1, id2)
        let calculatedName1 = IDRegistrar.name(of: id1)
        let calculatedName2 = IDRegistrar.name(of: id2)
        XCTAssertNotNil(calculatedName1)
        XCTAssertEqual(name1, calculatedName1)
        XCTAssertNotNil(calculatedName2)
        XCTAssertEqual(name2, calculatedName2)
        IDRegistrar.removeAll()
        XCTAssertNil(IDRegistrar.name(of: id1))
        XCTAssertNil(IDRegistrar.name(of: id2))
        let id3 = IDRegistrar.id(of: name1)
        let id4 = IDRegistrar.id(of: name2)
        XCTAssertNotEqual(id3, id4)
        let calculatedName3 = IDRegistrar.name(of: id3)
        let calculatedName4 = IDRegistrar.name(of: id4)
        XCTAssertNotNil(calculatedName3)
        XCTAssertEqual(name1, calculatedName3)
        XCTAssertNotNil(calculatedName4)
        XCTAssertEqual(name2, calculatedName4)
    }

}
