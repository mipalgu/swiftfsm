// import XCTest

// @testable import FSM
// import Mocks
// import XCTest

// @testable import Model

// final class ArrangementEnvironmentVariableTests: XCTestCase {

//     func testInit() {
//         let id = "id"
//         let initialValue = 2
//         let wrapper = ArrangementEnvironmentVariable(
//             wrappedValue: GlobalVariableHandlerMock(id: id, value: initialValue)
//         )
//         let handler = wrapper.wrappedValue
//         XCTAssertEqual(handler.id, id)
//         XCTAssertEqual(handler.value, initialValue)
//     }

//     func testWrappedValueReturnsNewInstances() {
//         let wrapper = ArrangementEnvironmentVariable(
//             wrappedValue: GlobalVariableHandlerMock(id: "id", value: 3)
//         )
//         let handler = wrapper.wrappedValue
//         let handler2 = wrapper.wrappedValue
//         XCTAssertNotIdentical(handler, handler2)
//         XCTAssertEqual(handler.id, handler2.id)
//         XCTAssertEqual(handler.value, handler2.value)
//     }

// }
