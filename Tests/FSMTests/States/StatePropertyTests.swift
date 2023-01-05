import XCTest

@testable import FSM

private struct TempFSM: LLFSM {

    struct Environment: EnvironmentSnapshot {

        var actuator: Int!

        var externalVariables: Bool!

        fileprivate var sensor: UInt8!

    }

    @State(
        name: "Ping",
        uses: [\.actuator, \.externalVariables, \.sensor],
        transitions: {
            Transition(to: \.$pong) { _ in false }
        }
    )
    var ping = EmptyLLFSMState()

    struct PongContext: ContextProtocol {

        var executeOnEntry: Bool = false

        var executeInternal: Bool = false

        var executeOnExit: Bool = false

        var executeOnSuspend: Bool = false

        var executeOnResume: Bool = false

    }

    @State(
        name: "Pong",
        uses: \.actuator, \.externalVariables, \.sensor,
        transitions: {
            Transition(to: "Ping", context: PongContext.self) { $0.executeInternal }
        }
    )
    var pong = CallbackLLFSMState<PongContext, Context, Environment, Parameters, Result> {
        $0.executeOnEntry = true
    } internal: {
        $0.executeInternal = true
    } onExit: {
        $0.executeOnExit = true
    } onSuspend: {
        $0.executeOnSuspend = true
    } onResume: {
        $0.executeOnResume = true
    }

    var pingProperty: State {
        _ping
    }

    var pongProperty: State {
        _pong
    }

    let initialState = \Self.$ping

}

final class StatePropertyTests: XCTestCase {

    fileprivate typealias TempContext = FSMContext<
        TempFSM.Context,
        TempFSM.Environment,
        TempFSM.Parameters,
        TempFSM.Result
    >

    fileprivate typealias PongContext = StateContext<
        TempFSM.PongContext,
        TempFSM.Context,
        TempFSM.Environment,
        TempFSM.Parameters,
        TempFSM.Result
    >

    fileprivate typealias PongState = CallbackLLFSMState<
        TempFSM.PongContext,
        TempFSM.Context,
        TempFSM.Environment,
        TempFSM.Parameters,
        TempFSM.Result
    >

    fileprivate typealias EmptyState = EmptyLLFSMState<
        TempFSM.Context,
        TempFSM.Environment,
        TempFSM.Parameters,
        TempFSM.Result
    >

    fileprivate typealias StateType = AnyLLFSMState<
        TempFSM.Context,
        TempFSM.Environment,
        TempFSM.Parameters,
        TempFSM.Result
    >

    fileprivate typealias Property = StateProperty<StateType, TempFSM>

    private var pongProperty: Property!

    override func setUp() {
        pongProperty = TempFSM().pongProperty
    }

    func testInit() {
        let wrappedValue = EmptyState()
        let name = "Ping"
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [\.actuator, \.externalVariables, \.sensor]
        let info = StateInformation(name: name)
        let property = TempFSM().pingProperty
        XCTAssertEqual(wrappedValue, property.wrappedValue.base as? EmptyState)
        XCTAssertEqual(property.information, info)
        XCTAssertEqual(property.environmentVariables, keyPaths)
    }

    func testVariadicInit() {
        let fsm = TempFSM()
        let name = "Pong"
        let pingInfo = StateInformation(name: "Ping")
        let pongInfo = StateInformation(name: name)
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [\.actuator, \.externalVariables, \.sensor]
        let property = fsm.pongProperty
        XCTAssertEqual(property.information, pongInfo)
        XCTAssertEqual(property.information.name, name)
        XCTAssertEqual(property.environmentVariables, keyPaths)
        XCTAssertEqual(property.transitions.count, 1)
        let context1 = TempContext(
            state: TempFSM.PongContext(
                executeOnEntry: false,
                executeInternal: false,
                executeOnExit: false,
                executeOnSuspend: false,
                executeOnResume: false
            ),
            fsm: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let context2 = TempContext(
            state: TempFSM.PongContext(
                executeOnEntry: true,
                executeInternal: true,
                executeOnExit: true,
                executeOnSuspend: true,
                executeOnResume: true
            ),
            fsm: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        XCTAssertNotNil(property.wrappedValue.base as? PongState)
        guard let pongState = property.wrappedValue.base as? PongState else{
            return
        }
        var pongContext = PongContext(fsmContext: context1)
        XCTAssertFalse(pongContext.executeOnEntry)
        XCTAssertFalse(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onEntry(context: &pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertFalse(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.internal(context: &pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onExit(context: &pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onSuspend(context: &pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertTrue(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onResume(context: &pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertTrue(pongContext.executeOnSuspend)
        XCTAssertTrue(pongContext.executeOnResume)
        for transition in property.transitions {
            XCTAssertEqual(transition.target(fsm), pingInfo)
            XCTAssertFalse(transition.canTransition(from: context1))
            XCTAssertTrue(transition.canTransition(from: context2))
        }
    }

    func testErasedGetters() {
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [\.actuator, \.externalVariables, \.sensor]
        XCTAssertEqual(
            keyPaths,
            pongProperty.erasedEnvironmentVariables as? [PartialKeyPath<TempFSM.Environment>]
        )
        XCTAssertNotNil(pongProperty.erasedState as? StateType)
        guard let stateType = pongProperty.erasedState as? StateType else {
            return
        }
        XCTAssertNotNil(stateType.base as? PongState)
        XCTAssertEqual(pongProperty.projectedValue, pongProperty.information)
        let erasedTransitions = pongProperty.erasedTransitions(for: TempFSM())
        XCTAssertNotNil(erasedTransitions as? [AnyTransition<TempContext, StateID>])
        guard let actualTransitions = erasedTransitions as? [AnyTransition<TempContext, StateID>] else {
            return
        }
        XCTAssertEqual(actualTransitions.count, 1)
        guard actualTransitions.count == 1 else {
            return
        }
        let transition = actualTransitions[0]
        let pingInfo = StateInformation(name: "Ping")
        XCTAssertEqual(transition.target, pingInfo.id)
        let context1 = TempContext(
            state: TempFSM.PongContext(
                executeOnEntry: false,
                executeInternal: false,
                executeOnExit: false,
                executeOnSuspend: false,
                executeOnResume: false
            ),
            fsm: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let context2 = TempContext(
            state: TempFSM.PongContext(
                executeOnEntry: true,
                executeInternal: true,
                executeOnExit: true,
                executeOnSuspend: true,
                executeOnResume: true
            ),
            fsm: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        XCTAssertFalse(transition.canTransition(from: context1))
        XCTAssertTrue(transition.canTransition(from: context2))
    }

}
