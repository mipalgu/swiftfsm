import FSM
import InMemoryVariables
import Mocks
import XCTest

@testable import Model

final class GlobalVariablePropertyTests: XCTestCase {

    struct Snapshot: EnvironmentSnapshot {

        var bool: Bool!

    }

    func testHandlerInit() {
        let mock = GlobalVariableHandlerMock(id: "mock", value: false)
        let property = GlobalVariableProperty<Snapshot, GlobalVariableHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool
        )
        XCTAssertIdentical(mock, property.projectedValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testInMemoryInit() {
        let id = "inMemory"
        let initialValue = true
        let property = GlobalVariableProperty<Snapshot, InMemoryGlobalVariable<Bool>>(
            id: "inMemory",
            initialValue: initialValue,
            mapsTo: \.bool
        )
        XCTAssertEqual(property.projectedValue.id, id)
        XCTAssertEqual(property.projectedValue.value, initialValue)
        XCTAssertEqual(\Snapshot.bool, property.mapPath)
    }

    func testWrappedValueDelegatesToHandler() {
        let mock = GlobalVariableHandlerMock(id: "mock2", value: false)
        var property = GlobalVariableProperty<Snapshot, GlobalVariableHandlerMock<Bool>>(
            handler: mock,
            mapsTo: \.bool
        )
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
