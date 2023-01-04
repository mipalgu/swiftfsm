import XCTest

@testable import FSM

final class ExternalVariablePropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testInit() {
        let mock = ExternalVariableHandlerMock(id: "mock", value: false)
        let property = ExternalVariableProperty<Snapshot, ExternalVariableHandlerMock>(
            handler: mock,
            mapsTo: \.bool
        )
        XCTAssertIdentical(mock, property.wrappedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = ExternalVariableHandlerMock(id: "mock", value: false)
        var property = ExternalVariableProperty<Snapshot, ExternalVariableHandlerMock>(
            handler: mock,
            mapsTo: \.bool
        )
        XCTAssertEqual(property.wrappedValue.takeSnapshot(), false)
        XCTAssertEqual(mock.calls.count, 1)
        XCTAssertEqual(mock.takeSnapshotCalls, 1)
        property.wrappedValue.saveSnapshot(value: true)
        XCTAssertEqual(mock.calls.count, 2)
        XCTAssertEqual(mock.saveSnapshotCalls, [true])
        XCTAssertEqual(property.wrappedValue.takeSnapshot(), true)
        XCTAssertEqual(mock.calls.count, 3)
        XCTAssertEqual(mock.takeSnapshotCalls, 2)
    }

}
