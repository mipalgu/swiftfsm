import FSM
import LLFSMs
import XCTest

@testable import Model

private struct TempFSM: LLFSM {

    struct Environment: EnvironmentSnapshot {

        @Actuator
        var actuator: Int!

        @ExternalVariable
        var externalVariables: Bool!

        @Sensor
        var sensor: UInt8!

    }

    @State(
        name: "Ping",
        uses: [\.$actuator, \.$externalVariables, \.$sensor],
        transitions: {
            Transition(to: \.$pong) { _ in false }
        }
    )
    var ping = EmptyLLFSMState()

    @State(name: "Pung", uses: [\.$actuator])
    var pung = EmptyLLFSMState()

    @State(name: "Pang")
    var pang = EmptyLLFSMState()

    struct PongContext: ContextProtocol {

        var executeOnEntry: Bool = false

        var executeInternal: Bool = false

        var executeOnExit: Bool = false

        var executeOnSuspend: Bool = false

        var executeOnResume: Bool = false

    }

    @State(
        name: "Pong",
        uses: \.$actuator,
            \.$externalVariables,
            \.$sensor,
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

    var pungProperty: State {
        _pung
    }

    var pangProperty: State {
        _pang
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

    fileprivate typealias PingContext = StateContext<
        EmptyDataStructure,
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

    fileprivate typealias TempStateContext = AnyStateContext<
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
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [
            \.$actuator.wrappedValue,
            \.$externalVariables.wrappedValue,
            \.$sensor.wrappedValue
        ]
        let info = StateInformation(name: name)
        let property = TempFSM().pingProperty
        XCTAssertEqual(wrappedValue, property.wrappedValue.base as? EmptyState)
        XCTAssertEqual(property.information, info)
        XCTAssertEqual(property.environmentVariables, keyPaths)
        XCTAssertEqual(property.transitions.count, 1)
        guard property.transitions.count == 1 else {
            return
        }
        let transition = property.transitions[0]
        let fsmContext = TempContext(
            context: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let context = PingContext(context: EmptyDataStructure(), fsmContext: fsmContext)
        XCTAssertFalse(transition.canTransition(from: context))
        let pongInfo = StateInformation(name: "Pong")
        XCTAssertEqual(transition.target(TempFSM()), pongInfo)
    }

    func testDefaultValuesOfInit() {
        let wrappedValue = EmptyState()
        let name = "Pung"
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [\.$actuator.wrappedValue]
        let info = StateInformation(name: name)
        let property = TempFSM().pungProperty
        XCTAssertEqual(wrappedValue, property.wrappedValue.base as? EmptyState)
        XCTAssertEqual(property.information, info)
        XCTAssertEqual(property.environmentVariables, keyPaths)
        XCTAssertTrue(property.transitions.isEmpty)
    }

    func testVariadicInit() {
        let fsm = TempFSM()
        let name = "Pong"
        let pingInfo = StateInformation(name: "Ping")
        let pongInfo = StateInformation(name: name)
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [
            \.$actuator.wrappedValue,
            \.$externalVariables.wrappedValue,
            \.$sensor.wrappedValue
        ]
        let property = fsm.pongProperty
        XCTAssertEqual(property.information, pongInfo)
        XCTAssertEqual(property.information.name, name)
        XCTAssertEqual(property.environmentVariables, keyPaths)
        XCTAssertEqual(property.transitions.count, 1)
        let fsmContext = TempContext(
            context: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let falseContext = PongContext(
            context: TempFSM.PongContext(
                executeOnEntry: false,
                executeInternal: false,
                executeOnExit: false,
                executeOnSuspend: false,
                executeOnResume: false
            ),
            fsmContext: fsmContext
        )
        let context1 = PongContext(
            context: TempFSM.PongContext(
                executeOnEntry: false,
                executeInternal: false,
                executeOnExit: false,
                executeOnSuspend: false,
                executeOnResume: false
            ),
            fsmContext: fsmContext
        )
        let context2 = PongContext(
            context: TempFSM.PongContext(
                executeOnEntry: true,
                executeInternal: true,
                executeOnExit: true,
                executeOnSuspend: true,
                executeOnResume: true
            ),
            fsmContext: fsmContext
        )
        XCTAssertNotNil(property.wrappedValue.base as? PongState)
        guard let pongState = property.wrappedValue.base as? PongState else {
            return
        }
        let pongContext = context1
        XCTAssertFalse(pongContext.executeOnEntry)
        XCTAssertFalse(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onEntry(context: pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertFalse(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.internal(context: pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertFalse(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onExit(context: pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertFalse(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onSuspend(context: pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertTrue(pongContext.executeOnSuspend)
        XCTAssertFalse(pongContext.executeOnResume)
        pongState.onResume(context: pongContext)
        XCTAssertTrue(pongContext.executeOnEntry)
        XCTAssertTrue(pongContext.executeInternal)
        XCTAssertTrue(pongContext.executeOnExit)
        XCTAssertTrue(pongContext.executeOnSuspend)
        XCTAssertTrue(pongContext.executeOnResume)
        for transition in property.transitions {
            XCTAssertEqual(transition.target(fsm), pingInfo)
            XCTAssertFalse(transition.canTransition(from: falseContext))
            XCTAssertTrue(transition.canTransition(from: context1))
            XCTAssertTrue(transition.canTransition(from: context2))
        }
    }

    func testDefaultValuesOfVariadicInit() {
        let wrappedValue = EmptyState()
        let name = "Pang"
        let info = StateInformation(name: name)
        let property = TempFSM().pangProperty
        XCTAssertEqual(wrappedValue, property.wrappedValue.base as? EmptyState)
        XCTAssertEqual(property.information, info)
        XCTAssertTrue(property.environmentVariables.isEmpty)
        XCTAssertTrue(property.transitions.isEmpty)
    }

    func testErasedGetters() {
        let keyPaths: [PartialKeyPath<TempFSM.Environment>] = [
            \.$actuator.wrappedValue,
            \.$externalVariables.wrappedValue,
            \.$sensor.wrappedValue
        ]
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
        XCTAssertNotNil(erasedTransitions as? [AnyTransition<TempStateContext, StateID>])
        guard let actualTransitions = erasedTransitions as? [AnyTransition<TempStateContext, StateID>] else {
            return
        }
        XCTAssertEqual(actualTransitions.count, 1)
        guard actualTransitions.count == 1 else {
            return
        }
        let transition = actualTransitions[0]
        let pingInfo = StateInformation(name: "Ping")
        XCTAssertEqual(transition.target, pingInfo.id)
        let fsmContext = TempContext(
            context: EmptyDataStructure(),
            environment: TempFSM.Environment(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let context1 = PongContext(
            context: TempFSM.PongContext(
                executeOnEntry: false,
                executeInternal: false,
                executeOnExit: false,
                executeOnSuspend: false,
                executeOnResume: false
            ),
            fsmContext: fsmContext
        )
        let context2 = PongContext(
            context: TempFSM.PongContext(
                executeOnEntry: true,
                executeInternal: true,
                executeOnExit: true,
                executeOnSuspend: true,
                executeOnResume: true
            ),
            fsmContext: fsmContext
        )
        XCTAssertFalse(transition.canTransition(from: context1))
        XCTAssertTrue(transition.canTransition(from: context2))
    }

}
