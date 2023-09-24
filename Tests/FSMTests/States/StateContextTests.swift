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

    typealias FalseContext = StateContext<SomeData, SomeData, SomeData, SomeData, SomeData>

    typealias MultiContext = StateContext<SContext, FContext, EContext, PContext, RContext>

    let falseData = SomeData(bool: false)

    let trueData = SomeData(bool: true)

    var falseFSMContext: FSMContext<SomeData, SomeData, SomeData, SomeData>!

    var falseContext: StateContext<SomeData, SomeData, SomeData, SomeData, SomeData>!

    var trueFSMContext: FSMContext<SomeData, SomeData, SomeData, SomeData>!

    var multiFSMContext: FSMContext<FContext, EContext, PContext, RContext>!

    var multiContext: StateContext<SContext, FContext, EContext, PContext, RContext>!

    override func setUp() {
        falseFSMContext = FSMContext(
            context: falseData,
            environment: falseData,
            parameters: falseData,
            result: falseData,
            status: .executing(transitioned: true)
        )
        falseContext = FalseContext(context: falseData, fsmContext: falseFSMContext)
        trueFSMContext = FSMContext(
            context: trueData,
            environment: trueData,
            parameters: trueData,
            result: trueData,
            status: .executing(transitioned: true)
        )
        multiFSMContext = FSMContext(
            context: FContext(),
            environment: EContext(),
            parameters: PContext(),
            result: RContext(),
            status: .executing(transitioned: true)
        )
        multiContext = MultiContext(context: SContext(), fsmContext: multiFSMContext)
    }

    func testInit() {
        let state = SomeData(bool: true)
        let context = FalseContext(context: state, fsmContext: falseFSMContext)
        XCTAssertEqual(state, context.context)
        XCTAssertEqual(context.fsmContext.context, falseFSMContext.context)
        XCTAssertEqual(context.fsmContext.duration, falseFSMContext.duration)
        XCTAssertEqual(context.fsmContext.environment, falseFSMContext.environment)
        XCTAssertEqual(context.fsmContext.parameters, falseFSMContext.parameters)
        XCTAssertEqual(context.fsmContext.result, falseFSMContext.result)
        XCTAssertEqual(context.fsmContext.status, falseFSMContext.status)
    }

    // swiftlint:disable:next function_body_length
    func testGettersAndSetters() {
        let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
        XCTAssertEqual(context.context, falseData)
        XCTAssertEqual(context.fsmContext.context, falseFSMContext.context)
        XCTAssertEqual(context.fsmContext.duration, falseFSMContext.duration)
        XCTAssertEqual(context.fsmContext.environment, falseFSMContext.environment)
        XCTAssertEqual(context.fsmContext.parameters, falseFSMContext.parameters)
        XCTAssertEqual(context.fsmContext.result, falseFSMContext.result)
        XCTAssertEqual(context.fsmContext.status, falseFSMContext.status)
        context.context = trueData
        XCTAssertEqual(context.context, trueData)
        XCTAssertEqual(context.fsmContext.context, falseFSMContext.context)
        XCTAssertEqual(context.fsmContext.duration, falseFSMContext.duration)
        XCTAssertEqual(context.fsmContext.environment, falseFSMContext.environment)
        XCTAssertEqual(context.fsmContext.parameters, falseFSMContext.parameters)
        XCTAssertEqual(context.fsmContext.result, falseFSMContext.result)
        XCTAssertEqual(context.fsmContext.status, falseFSMContext.status)
    }

    func testIsFinished() {
        let statuses = FSMStatus.allCases.filter { $0 != .finished }
        for status in statuses {
            let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
            context.fsmContext.status = status
            XCTAssertFalse(context.isFinished)
        }
        let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
        context.fsmContext.status = .finished
        XCTAssertTrue(context.isFinished)
    }

    func testIsSuspended() {
        let statuses = FSMStatus.allCases.filter {
            $0 != .suspended(transitioned: false) && $0 != .suspended(transitioned: true)
        }
        let falseData = SomeData(bool: false)
        for status in statuses {
            let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
            context.fsmContext.status = status
            XCTAssertFalse(context.isSuspended)
        }
        let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
        context.fsmContext.status = .suspended(transitioned: false)
        XCTAssertTrue(context.isSuspended)
        let context2 = FalseContext(context: falseData, fsmContext: falseFSMContext)
        context2.fsmContext.status = .suspended(transitioned: true)
        XCTAssertTrue(context2.isSuspended)
    }

    func testRestart() {
        for status in FSMStatus.allCases {
            let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
            context.fsmContext.status = status
            context.restart()
            XCTAssertEqual(context.fsmContext.status, .restarting)
        }
    }

    func testResume() {
        for status in FSMStatus.allCases {
            let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
            context.fsmContext.status = status
            context.resume()
            XCTAssertEqual(context.fsmContext.status, .resuming)
        }
    }

    func testSuspend() {
        for status in FSMStatus.allCases {
            let context = FalseContext(context: falseData, fsmContext: falseFSMContext)
            context.fsmContext.status = status
            context.suspend()
            XCTAssertEqual(context.fsmContext.status, .suspending)
        }
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
            multiContext.context.sBool.toggle()
        }
    }

    func testStateDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.context.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.context.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.context.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.context.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.context.sBool.toggle()
            }
        }
    }

    func testStateDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.context.sBool.toggle()
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
            multiContext.fsmContext.context.fBool.toggle()
        }
    }

    func testFSMDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.fsmContext.context.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.fsmContext.context.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.fsmContext.context.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.fsmContext.context.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.fsmContext.context.fBool.toggle()
            }
        }
    }

    func testFSMDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.fsmContext.context.fBool.toggle()
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
            multiContext.fsmContext.environment.eBool.toggle()
        }
    }

    func testEnvironmentDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                multiContext.fsmContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                multiContext.fsmContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                multiContext.fsmContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                multiContext.fsmContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                multiContext.fsmContext.environment.eBool.toggle()
            }
        }
    }

    func testEnvironmentDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                multiContext.fsmContext.environment.eBool.toggle()
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
            _ = multiContext.fsmContext.parameters.pBool
        }
    }

    func testParametersDirectAccessPerformance_10() {
        measure {
            for _ in 0..<10 {
                _ = multiContext.fsmContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_100() {
        measure {
            for _ in 0..<100 {
                _ = multiContext.fsmContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_1000() {
        measure {
            for _ in 0..<1000 {
                _ = multiContext.fsmContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_10_000() {
        measure {
            for _ in 0..<10_000 {
                _ = multiContext.fsmContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_100_000() {
        measure {
            for _ in 0..<100_000 {
                _ = multiContext.fsmContext.parameters.pBool
            }
        }
    }

    func testParametersDirectAccessPerformance_1_000_000() {
        measure {
            for _ in 0..<1_000_000 {
                _ = multiContext.fsmContext.parameters.pBool
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
