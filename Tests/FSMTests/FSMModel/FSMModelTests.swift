import XCTest

@testable import FSM

final class FSMModelTests: XCTestCase {

    typealias FSMType = FiniteStateMachine<
            FSMMock.StateType,
            FSMMock.Ringlet,
            FSMMock.Parameters,
            FSMMock.Result,
            FSMMock.Context,
            FSMMock.Environment
        >

    let mock = FSMMock()

    func test_extractsNameFromType() {
        XCTAssertEqual(mock.name, "FSMMock")
    }

    func test_initialReturnsAFiniteStateMachine() {
        let (fsm, _) = mock.initial
        XCTAssertEqual("\(type(of: fsm))", "\(FSMType.self)")
        let casted = fsm as? FSMType
        XCTAssertNotNil(casted)
    }

}
