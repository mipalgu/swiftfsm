import FSM
import Mocks
import XCTest

@testable import Model

final class ActuatorPropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = ActuatorHandlerMock<Bool>(id: "mock", initialValue: false)
        let property = ActuatorProperty<Snapshot, ActuatorHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool
        )
        XCTAssertIdentical(mock, property.wrappedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = ActuatorHandlerMock<Bool>(id: "mock", initialValue: false)
        let property = ActuatorProperty<Snapshot, ActuatorHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool
        )
        property.wrappedValue.saveSnapshot(value: true)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.saveSnapshotCalls, [true])
        property.wrappedValue.saveSnapshot(value: false)
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.saveSnapshotCalls, [true, false])
    }

}
