import LLFSMs
import Mocks
import Model
import XCTest

@testable import FSM

final class FSMTests: XCTestCase {

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

    typealias SchedulerContextType = SchedulerContext<
        FSMMock.StateType,
        FSMMock.Ringlet.Context,
        FSMMock.Context,
        FSMMock.Environment,
        FSMMock.Parameters,
        FSMMock.Result
    >

    let mock = FSMMock()

    let actuators: [(PartialKeyPath<FSMMock.Environment>, AnyActuatorHandler<FSMMock.Environment>)]
        = [ArrangementActuator(
            wrappedValue: ActuatorHandlerMock(id: "exitActuator", initialValue: false)
        ).anyActuator(mapsTo: \.$exitActuator)]

    // swiftlint:disable:next line_length
    let externalVariables: [(PartialKeyPath<FSMMock.Environment>, AnyExternalVariableHandler<FSMMock.Environment>)]
        = [ArrangementExternalVariable(
            wrappedValue: ExternalVariableHandlerMock(id: "exitExternalVariable", value: false)
        ).anyExternalVariable(mapsTo: \.$exitExternalVariable)]

    // swiftlint:disable:next line_length
    let globalVariables: [(PartialKeyPath<FSMMock.Environment>, AnyGlobalVariableHandler<FSMMock.Environment>)]
        = [ArrangementGlobalVariable(
            wrappedValue: GlobalVariableHandlerMock(id: "exitGlobalVariable", value: false)
        ).anyGlobalVariable(mapsTo: \.$exitGlobalVariable)]

    let sensors: [(PartialKeyPath<FSMMock.Environment>, AnySensorHandler<FSMMock.Environment>)]
        = [ArrangementSensor(
            wrappedValue: SensorHandlerMock(id: "exitSensor", value: false)
        ).anySensor(mapsTo: \FSMMock.Environment.$exitSensor)]

    func test_extractsNameFromType() {
        XCTAssertEqual(mock.name, "FSMMock")
    }

    func test_initialReturnsAFiniteStateMachine() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        XCTAssertEqual("\(type(of: data.executable))", "\(FSMType.self)")
        let casted = data.executable as? FSMType
        XCTAssertNotNil(casted)
    }

    func test_initialReturnsAFiniteStateMachineWithAllStates() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        guard let casted = data.executable as? FSMType else {
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
            "__Previous",
        ]
        let actualStates = Set(
            UnsafeBufferPointer(start: casted.states, count: casted.statesCount).map(\.name)
        )
        XCTAssertEqual(expectedStates, actualStates)
    }

    func test_initialReturnsAnFSMWithStateContexts() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        guard let casted = data.executable as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let callbackStates: Set<String> = ["Ping", "Pong", "Exit"]
        let emptyStates: Set<String> = []
        let ignoredStates: Set<String> = ["Pang"]
        let buffer = UnsafeBufferPointer(start: casted.states, count: casted.statesCount)
        for state in buffer where !ignoredStates.contains(state.name) {
            let base = state.stateType.base
            if callbackStates.contains(state.name) {
                XCTAssertEqual("\(type(of: base))", "\(CallbackStateType<EmptyDataStructure>.self)")
            } else if emptyStates.contains(state.name) || state.name.hasPrefix("__") {
                XCTAssertEqual(
                    "\(type(of: base))",
                    "\(EmptyStateType.self)",
                    "Invalid type of state \(state.name)"
                )
            } else {
                XCTFail("Unhandled state: \(state.name)")
            }
        }
        guard let pang = buffer.first(where: { $0.name == "Pang" }) else {
            XCTFail("Unable to locate pang state.")
            return
        }
        let base = pang.stateType.base
        XCTAssertEqual("\(type(of: base))", "\(CallbackStateType<FSMMock.PangData>.self)")
    }

    func test_initialCreatesFactoryThatHandlesNilParameters() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        let context = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { context.deallocate() }
        data.initialiseContext(parameters: nil, context: context)
        XCTAssertEqual("\(type(of: context.pointee))", "\(SchedulerContextType.self)")
    }

    func test_initialCreatesFactoryThatHandlesParameters() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        let context = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { context.deallocate() }
        data.initialiseContext(parameters: FSMMock.Parameters(), context: context)
        XCTAssertEqual("\(type(of: context.pointee))", "\(SchedulerContextType.self)")
    }

    func test_initialCreatesPseudoInitialState() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        guard let fsm = data.executable as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let buffer = UnsafeBufferPointer(start: fsm.states, count: fsm.statesCount)
        guard let initial = buffer.first(where: { $0.name == "__Initial" }) else {
            XCTFail("Unable to find initial pseudo state.")
            return
        }
        let context = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { context.deallocate() }
        data.initialiseContext(parameters: nil, context: context)
        XCTAssertEqual("\(type(of: context.pointee))", "\(SchedulerContextType.self)")
        guard let typedContext = context.pointee as? SchedulerContextType else {
            XCTFail("Unable to cast data to \(SchedulerContextType.self)")
            return
        }
        XCTAssertEqual(initial.id, typedContext.initialState)
        XCTAssertEqual(initial.id, typedContext.currentState)
    }

    func test_initialCreatesPseudoPreviousState() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        guard let fsm = data.executable as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let buffer = UnsafeBufferPointer(start: fsm.states, count: fsm.statesCount)
        guard let previous = buffer.first(where: { $0.name == "__Previous" }) else {
            XCTFail("Unable to find initial pseudo state.")
            return
        }
        let context = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { context.deallocate() }
        data.initialiseContext(parameters: nil, context: context)
        XCTAssertEqual("\(type(of: context.pointee))", "\(SchedulerContextType.self)")
        guard let typedContext = context.pointee as? SchedulerContextType else {
            XCTFail("Unable to cast data to \(SchedulerContextType.self)")
            return
        }
        XCTAssertEqual(previous.id, typedContext.data.previousState)
    }

    func test_initialCreatesPseudoSuspendState() {
        let data = mock.initial(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
        guard let fsm = data.executable as? FSMType else {
            XCTFail("Unable to cast fsm to \(FSMType.self)")
            return
        }
        let buffer = UnsafeBufferPointer(start: fsm.states, count: fsm.statesCount)
        guard let suspend = buffer.first(where: { $0.name == "__Suspend" }) else {
            XCTFail("Unable to find initial pseudo state.")
            return
        }
        let context = UnsafeMutablePointer<SchedulerContextProtocol>.allocate(capacity: 1)
        defer { context.deallocate() }
        data.initialiseContext(parameters: nil, context: context)
        XCTAssertEqual("\(type(of: context.pointee))", "\(SchedulerContextType.self)")
        guard var typedContext = context.pointee as? SchedulerContextType else {
            XCTFail("Unable to cast data to \(SchedulerContextType.self)")
            return
        }
        XCTAssertEqual(suspend.id, typedContext.suspendState)
        typedContext.data.suspend()
        XCTAssertEqual(suspend.id, typedContext.currentState)
    }

    func test_dependencies() {
        let deps = mock.dependencies
        XCTAssertTrue(deps.isEmpty, "Mock should not contain any dependencies")
        //        XCTAssertEqual(deps.count, 1)
        //        guard let first = deps.first else {
        //            return
        //        }
        //        let meID = IDRegistrar.id(of: "Me")
        //        XCTAssertEqual(first, .sync(id: meID))
    }

    func test_dependenciesDoesNotContainDuplicates() {
        let deps = mock.dependencies
        let setOfDeps = Set(deps)
        XCTAssertEqual(deps.count, setOfDeps.count)
    }

}
