import XCTest

@testable import FSM

final class SensorPropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = SensorHandlerMock(id: "mock", value: false)
        let property = SensorProperty<Snapshot, SensorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertIdentical(mock, property.projectedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = SensorHandlerMock(id: "mock", value: false)
        let property = SensorProperty<Snapshot, SensorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertEqual(property.wrappedValue, false)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.getValueCalls, 1)
        XCTAssertEqual(property.wrappedValue, false)
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.getValueCalls, 2)
        XCTAssertEqual(mock.value, false)
    }

}
