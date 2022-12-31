import XCTest

@testable import FSM

final class SnapshotTests: XCTestCase {

    struct Person: EnvironmentSnapshot {

        var firstName: String = ""

        var lastName: String = ""

    }

    func testCanFetchAndSetPropertyUsingSnapshot() {
        var snapshot = Snapshot(data: Person(), whitelist: [])
        XCTAssertEqual(snapshot.get(\.firstName), "")
        snapshot.set(\.firstName, "Somebody")
        XCTAssertEqual(snapshot.get(\.firstName), "Somebody")
        XCTAssertEqual(snapshot.get(\.lastName), "")
        snapshot.set(\.lastName, "LastName")
        XCTAssertEqual(snapshot.get(\.lastName), "LastName")
    }

    func testCanFetchPropertyNotInWhitelist() {
        var snapshot = Snapshot(data: Person(), whitelist: [\.lastName])
        XCTAssertEqual(snapshot.get(\.firstName), "")
        snapshot.set(\.firstName, "Somebody")
        XCTAssertEqual(snapshot.get(\.firstName), "Somebody")
    }

}
