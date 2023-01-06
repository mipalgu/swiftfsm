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

    func testStateDirectAccessPerformance_1() {
        measure {
            multiContext.state.sBool.toggle()
        }
    }

    func testStateDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.state.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_1() {
        measure {
            multiContext.sBool.toggle()
        }
    }

    func testStateDynamicAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testStateDynamicAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.sBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_1() {
        measure {
            multiContext.fsm.fBool.toggle()
        }
    }

    func testFSMDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.fsm.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_1() {
        measure {
            multiContext.fBool.toggle()
        }
    }

    func testFSMDynamicAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testFSMDynamicAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.fBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_1() {
        measure {
            multiContext.environment.eBool.toggle()
        }
    }

    func testEnvironmentDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_1() {
        measure {
            multiContext.eBool.toggle()
        }
    }

    func testEnvironmentDynamicAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testEnvironmentDynamicAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.eBool.toggle()
            }
        }
    }

    func testParametersDirectAccessPerformance_1() {
        measure {
            _ = multiContext.parameters.pBool
        }
    }

    func testParametersDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = multiContext.parameters.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_1() {
        measure {
            _ = multiContext.pBool
        }
    }

    func testParametersDynamicAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = multiContext.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = multiContext.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = multiContext.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                _ = multiContext.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = multiContext.pBool
            }
        }
    }

    func testParametersDynamicAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = multiContext.pBool
            }
        }
    }

}
