import XCTest

@testable import FSM

final class StateContextTests: XCTestCase {

    struct SContext: ContextProtocol {

        var sBool: Bool = false

    }

    struct FContext: ContextProtocol {

        var fBool: Bool = false

    }

    struct EContext: EnvironmentSnapshot {

        var eBool: Bool = false

    }

    struct PContext: EnvironmentSnapshot {

        var pBool: Bool = false

    }

    struct RContext: EnvironmentSnapshot {

        var rBool: Bool = false

    }

    struct SomeData: ContextProtocol, EnvironmentSnapshot {

        var bool: Bool = false

    }

    let falseData = SomeData(bool: false)

    let trueData = SomeData(bool: true)

    var falseContext: StateContext<SomeData, SomeData, SomeData, SomeData, SomeData>!

    var multiContext: StateContext<SContext, FContext, EContext, PContext, RContext>!

    override func setUp() {
        falseContext = StateContext(
            state: falseData,
            fsm: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: .executing(transitioned: true)
        )
        multiContext = StateContext(
            state: SContext(),
            fsm: FContext(),
            environment: EContext(),
            parameters: PContext(),
            result: RContext(),
            status: .executing(transitioned: true)
        )
    }

    func testInit() {
        let state = SomeData(bool: true)
        let fsm = SomeData(bool: true)
        let environment = SomeData(bool: true)
        let parameters = SomeData(bool: true)
        let result = SomeData(bool: true)
        let status: FSMStatus = .suspending
        let context = StateContext(
            state: state,
            fsm: fsm,
            environment: environment,
            parameters: parameters,
            result: result,
            status: status
        )
        XCTAssertEqual(state, context.state)
        XCTAssertEqual(fsm, context.fsm)
        XCTAssertEqual(environment, context.environment)
        XCTAssertEqual(parameters, context.parameters)
        XCTAssertEqual(result, context.result)
        XCTAssertEqual(status, context.status)
    }

    func testConvenienceInit() {
        let state = SomeData(bool: true)
        let fsm = SomeData(bool: true)
        let environment = SomeData(bool: true)
        let parameters = SomeData(bool: true)
        let result = SomeData(bool: true)
        let context = StateContext(
            state: state,
            fsm: fsm,
            environment: environment,
            parameters: parameters,
            result: result
        )
        XCTAssertEqual(state, context.state)
        XCTAssertEqual(fsm, context.fsm)
        XCTAssertEqual(environment, context.environment)
        XCTAssertEqual(parameters, context.parameters)
        XCTAssertEqual(result, context.result)
        XCTAssertEqual(.executing(transitioned: true), context.status)
    }

    func testFSMContextInit() {
        let state = SomeData(bool: true)
        let fsm = SomeData(bool: true)
        let environment = SomeData(bool: true)
        let parameters = SomeData(bool: true)
        let result = SomeData(bool: true)
        let status: FSMStatus = .suspending
        let fsmContext = FSMContext(
            state: state as Sendable,
            fsm: fsm,
            environment: environment,
            parameters: parameters,
            result: result,
            status: status
        )
        let context = StateContext<SomeData, SomeData, SomeData, SomeData, SomeData>(fsmContext: fsmContext)
        XCTAssertEqual(state, context.state)
        XCTAssertEqual(fsm, context.fsm)
        XCTAssertEqual(environment, context.environment)
        XCTAssertEqual(parameters, context.parameters)
        XCTAssertEqual(result, context.result)
        XCTAssertEqual(status, context.status)
    }

    // swiftlint:disable:next function_body_length
    func testGettersAndSetters() {
        let suspending = FSMStatus.suspending
        let resuming = FSMStatus.resuming
        var context = StateContext(
            state: falseData,
            fsm: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: suspending
        )
        XCTAssertEqual(context.state, falseData)
        XCTAssertEqual(context.fsm, falseData)
        XCTAssertEqual(context.environment, falseData)
        XCTAssertEqual(context.parameters, falseData)
        XCTAssertEqual(context.result, falseData)
        XCTAssertEqual(context.status, suspending)
        context.state = trueData
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, falseData)
        XCTAssertEqual(context.environment, falseData)
        XCTAssertEqual(context.parameters, falseData)
        XCTAssertEqual(context.result, falseData)
        XCTAssertEqual(context.status, suspending)
        context.fsm = trueData
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, trueData)
        XCTAssertEqual(context.environment, falseData)
        XCTAssertEqual(context.parameters, falseData)
        XCTAssertEqual(context.result, falseData)
        XCTAssertEqual(context.status, suspending)
        context.environment = trueData
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, trueData)
        XCTAssertEqual(context.environment, trueData)
        XCTAssertEqual(context.parameters, falseData)
        XCTAssertEqual(context.result, falseData)
        XCTAssertEqual(context.status, suspending)
        context.parameters = trueData
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, trueData)
        XCTAssertEqual(context.environment, trueData)
        XCTAssertEqual(context.parameters, trueData)
        XCTAssertEqual(context.result, falseData)
        XCTAssertEqual(context.status, suspending)
        context.result = trueData
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, trueData)
        XCTAssertEqual(context.environment, trueData)
        XCTAssertEqual(context.parameters, trueData)
        XCTAssertEqual(context.result, trueData)
        XCTAssertEqual(context.status, suspending)
        context.status = resuming
        XCTAssertEqual(context.state, trueData)
        XCTAssertEqual(context.fsm, trueData)
        XCTAssertEqual(context.environment, trueData)
        XCTAssertEqual(context.parameters, trueData)
        XCTAssertEqual(context.result, trueData)
        XCTAssertEqual(context.status, resuming)
    }

    func testIsFinished() {
        let statuses = FSMStatus.allCases.filter { $0 != .finished }
        for status in statuses {
            let context = StateContext(
                state: falseData,
                fsm: falseData,
                environment: falseData,
                parameters: falseData,
                result: falseData,
                status: status
            )
            XCTAssertFalse(context.isFinished)
        }
        let context = StateContext(
            state: falseData,
            fsm: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: .finished
        )
        XCTAssertTrue(context.isFinished)
    }

    func testIsSuspended() {
        let statuses = FSMStatus.allCases.filter {
            $0 != .suspended(transitioned: false) && $0 != .suspended(transitioned: true)
        }
        let falseData = SomeData(bool: false)
        for status in statuses {
            let context = StateContext(
                state: falseData,
                fsm: falseData,
                environment: falseData,
                parameters: falseData,
                result: falseData,
                status: status
            )
            XCTAssertFalse(context.isSuspended)
        }
        let context = StateContext(
            state: falseData,
            fsm: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: .suspended(transitioned: false)
        )
        XCTAssertTrue(context.isSuspended)
        let context2 = StateContext(
            state: falseData,
            fsm: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: .suspended(transitioned: true)
        )
        XCTAssertTrue(context2.isSuspended)
    }

    func testRestart() {
        for status in FSMStatus.allCases {
            var context = StateContext(
                state: falseData,
                fsm: falseData,
                environment: falseData,
                parameters: falseData,
                result: falseData,
                status: status
            )
            context.restart()
            XCTAssertEqual(context.status, .restarting)
        }
    }

    func testResume() {
        for status in FSMStatus.allCases {
            var context = StateContext(
                state: falseData,
                fsm: falseData,
                environment: falseData,
                parameters: falseData,
                result: falseData,
                status: status
            )
            context.resume()
            XCTAssertEqual(context.status, .resuming)
        }
    }

    func testSuspend() {
        for status in FSMStatus.allCases {
            var context = StateContext(
                state: falseData,
                fsm: falseData,
                environment: falseData,
                parameters: falseData,
                result: falseData,
                status: status
            )
            context.suspend()
            XCTAssertEqual(context.status, .suspending)
        }
    }

    func testUpdateFromFSMContext() {
        let fsmContext = FSMContext(
            state: trueData,
            fsm: trueData,
            environment: trueData,
            parameters: trueData,
            result: trueData,
            status: .suspending
        )
        falseContext.update(from: fsmContext)
        XCTAssertEqual(falseContext.state, trueData)
        XCTAssertEqual(falseContext.fsm, trueData)
        XCTAssertEqual(falseContext.environment, trueData)
        XCTAssertEqual(falseContext.parameters, trueData)
        XCTAssertEqual(falseContext.result, trueData)
        XCTAssertEqual(falseContext.status, .suspending)
    }

    func testDynamicLookup() {
        XCTAssertFalse(multiContext.sBool)
        multiContext.sBool = true
        XCTAssertTrue(multiContext.sBool)
        XCTAssertFalse(multiContext.fBool)
        multiContext.fBool = true
        XCTAssertTrue(multiContext.fBool)
        XCTAssertFalse(multiContext.eBool)
        multiContext.eBool = true
        XCTAssertTrue(multiContext.eBool)
        XCTAssertFalse(multiContext.pBool)
        let multiContext2 = multiContext!
        XCTAssertTrue(multiContext2.sBool)
        XCTAssertTrue(multiContext2.fBool)
        XCTAssertTrue(multiContext2.eBool)
    }

}
