import Foundation
import XCTest

@testable import FSM

final class FSMStatusTests: XCTestCase {

    func testAllCases() {
        let expected: Set<FSMStatus> = [
            .executing(transitioned: false),
            .executing(transitioned: true),
            .finished,
            .restarted(transitioned: false),
            .restarted(transitioned: true),
            .restarting,
            .resumed(transitioned: false),
            .resumed(transitioned: true),
            .resuming,
            .suspended(transitioned: false),
            .suspended(transitioned: true),
            .suspending,
        ]
        let allCases = Set(FSMStatus.allCases)
        XCTAssertEqual(expected, allCases)
    }

    func testTransitioned() {
        let transitionedStatuses: Set<FSMStatus> = [
            .executing(transitioned: true),
            .restarted(transitioned: true),
            .resumed(transitioned: true),
            .suspended(transitioned: true),
        ]
        for status in transitionedStatuses {
            XCTAssertTrue(status.transitioned)
        }
        for status in FSMStatus.allCases where !transitionedStatuses.contains(status) {
            XCTAssertFalse(status.transitioned)
        }
    }

    func testEquality() {
        let cases = FSMStatus.allCases
        for (index, status) in cases.enumerated() {
            XCTAssertEqual(status, status)
            var others = cases
            others.remove(at: index)
            for other in others {
                XCTAssertNotEqual(status, other)
                XCTAssertNotEqual(other, status)
            }
        }
    }

    func testHashable() {
        for status in FSMStatus.allCases {
            var collection = Set<FSMStatus>()
            for status in FSMStatus.allCases {
                XCTAssertFalse(collection.contains(status))
            }
            collection.insert(status)
            XCTAssertTrue(collection.contains(status))
            for otherStatus in FSMStatus.allCases where otherStatus != status {
                XCTAssertFalse(collection.contains(otherStatus))
            }
            collection = Set(FSMStatus.allCases)
            for status in FSMStatus.allCases {
                XCTAssertTrue(collection.contains(status))
            }
            collection.remove(status)
            XCTAssertFalse(collection.contains(status))
            for otherStatus in FSMStatus.allCases where otherStatus != status {
                XCTAssertTrue(collection.contains(otherStatus))
            }
        }
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for status in FSMStatus.allCases {
            let result = try decoder.decode(FSMStatus.self, from: encoder.encode(status))
            XCTAssertEqual(status, result)
        }
    }

}
