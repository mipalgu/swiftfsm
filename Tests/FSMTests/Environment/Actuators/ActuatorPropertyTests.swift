import XCTest

@testable import FSM

final class ActuatorPropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = ActuatorHandlerMock(id: "mock", value: false)
        let property = ActuatorProperty<Snapshot, ActuatorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertIdentical(mock, property.projectedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = ActuatorHandlerMock(id: "mock", value: false)
        var property = ActuatorProperty<Snapshot, ActuatorHandlerMock>(handler: mock, mapsTo: \.bool)
        XCTAssertEqual(property.wrappedValue, false)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.getValueCalls, 1)
        property.wrappedValue = true
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.setValueCalls, [true])
        XCTAssertEqual(property.wrappedValue, true)
        XCTAssertEqual(mock.calls.count, 3)
        XCTAssertEqual(mock.getValueCalls, 2)
        XCTAssertEqual(mock.value, true)
    }

}
