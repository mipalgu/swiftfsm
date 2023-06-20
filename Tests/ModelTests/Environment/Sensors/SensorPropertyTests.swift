import FSM
import Mocks
import XCTest

@testable import Model

final class SensorPropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = SensorHandlerMock(id: "mock", value: false)
        let property = SensorProperty<Snapshot, SensorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertIdentical(mock, property.wrappedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = SensorHandlerMock(id: "mock", value: false)
        let property = SensorProperty<Snapshot, SensorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertEqual(property.wrappedValue.takeSnapshot(), false)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.takeSnapshotCalls, 1)
        XCTAssertEqual(property.wrappedValue.takeSnapshot(), false)
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.takeSnapshotCalls, 2)
    }

}
