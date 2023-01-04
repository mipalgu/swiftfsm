import XCTest

@testable import FSM

final class ActuatorPropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = ActuatorHandlerMock<Bool>(id: "mock")
        let property = ActuatorProperty<Snapshot, ActuatorHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool,
            initialValue: false
        )
        XCTAssertIdentical(mock, property.wrappedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
        XCTAssertFalse(property.initialValue)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = ActuatorHandlerMock<Bool>(id: "mock")
        let property = ActuatorProperty<Snapshot, ActuatorHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool,
            initialValue: false
        )
        property.wrappedValue.saveSnapshot(value: true)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.saveSnapshotCalls, [true])
        property.wrappedValue.saveSnapshot(value: false)
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.saveSnapshotCalls, [true, false])
    }

}
