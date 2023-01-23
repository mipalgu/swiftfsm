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

    typealias CallbackStateType<StatesContext: ContextProtocol> = CallbackLLFSMState<
            StatesContext,
            FSMMock.Context,
            FSMMock.Environment,
            FSMMock.Parameters,
            FSMMock.Result
        >

    typealias EmptyStateType = EmptyLLFSMState<
            FSMMock.Context,
            FSMMock.Environment,
            FSMMock.Parameters,
            FSMMock.Result
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

    func test_initialReturnsAFiniteStateMachineWithAllStates() {
        let (fsm, _) = mock.initial
        guard let casted = fsm as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let expectedStates: Set<String> = [
            "Ping",
            "Pong",
            "Pang",
            "Exit",
            "__Initial",
            "__Suspend",
            "__Previous"
        ]
        let actualStates = Set(casted.states.map(\.name))
        XCTAssertEqual(expectedStates, actualStates)
    }

    func test_initialReturnsAnFSMWithStateContexts() {
        let (fsm, _) = mock.initial
        guard let casted = fsm as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let callbackStates: Set<String> = ["Ping", "Pong"]
        let emptyStates: Set<String> = ["Exit"]
        let ignoredStates: Set<String> = ["Pang"]
        for state in casted.states where !ignoredStates.contains(state.name) {
            let base = state.stateType.base
            if callbackStates.contains(state.name) {
                XCTAssertEqual("\(type(of: base))", "\(CallbackStateType<EmptyDataStructure>.self)")
            } else if emptyStates.contains(state.name) || state.name.hasPrefix("__") {
                XCTAssertEqual("\(type(of: base))", "\(EmptyStateType.self)")
            } else {
                XCTFail("Unhandled state: \(state.name)")
            }
        }
        guard let pang = casted.states.first(where: { $0.name == "Pang" }) else {
            XCTFail("Unable to locate pang state.")
            return
        }
        let base = pang.stateType.base
        XCTAssertEqual("\(type(of: base))", "\(CallbackStateType<FSMMock.PangData>.self)")
    }

}
