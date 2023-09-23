import XCTest

@testable import Verification

final class CallMethodTests: XCTestCase {

    let asynchronous = Call.Method.asynchronous
    let synchronous = Call.Method.synchronous

    func testRawValue() {
        XCTAssertEqual("asynchronous", Call.Method.asynchronous.rawValue)
        XCTAssertEqual("synchronous", Call.Method.synchronous.rawValue)
    }

    func testRawValueInit() {
        XCTAssertEqual(asynchronous, Call.Method(rawValue: "asynchronous"))
        XCTAssertEqual(synchronous, Call.Method(rawValue: "synchronous"))
        XCTAssertNil(Call.Method(rawValue: "undefined"))
    }

    func testEquality() {
        XCTAssertEqual(asynchronous, asynchronous)
        XCTAssertNotEqual(synchronous, asynchronous)
        XCTAssertNotEqual(asynchronous, synchronous)
        XCTAssertEqual(synchronous, synchronous)
    }

    func testHashable() {
        var collection: Set<Call.Method> = []
        XCTAssertFalse(collection.contains(asynchronous), "Expected collection to be empty.")
        XCTAssertFalse(collection.contains(synchronous), "Expected collection to be empty.")
        collection.insert(asynchronous)
        XCTAssertTrue(collection.contains(asynchronous), "Expected collection to contain asynchronouse.")
        XCTAssertFalse(collection.contains(synchronous), "Expected collection to not contain synchronous.")
        collection.insert(synchronous)
        XCTAssertTrue(collection.contains(asynchronous), "Expected collection to contain asynchronouse.")
        XCTAssertTrue(collection.contains(synchronous), "Expected collection to contain synchronous.")
        collection.remove(asynchronous)
        XCTAssertFalse(collection.contains(asynchronous), "Expected collection to not contain asynchronouse.")
        XCTAssertTrue(collection.contains(synchronous), "Expected collection to contain synchronous.")
    }

    func testComparable() {
        XCTAssertLessThan(asynchronous, synchronous)
        XCTAssertLessThanOrEqual(asynchronous, asynchronous)
        XCTAssertLessThanOrEqual(synchronous, synchronous)
        XCTAssertGreaterThan(synchronous, asynchronous)
        XCTAssertGreaterThanOrEqual(asynchronous, asynchronous)
        XCTAssertGreaterThanOrEqual(synchronous, synchronous)
    }

    func testCaseIterable() {
        XCTAssertEqual([asynchronous, synchronous].sorted(), Call.Method.allCases)
    }

}
