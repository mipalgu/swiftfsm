import Mocks
import XCTest

@testable import FSM

final class FSMContextTests: XCTestCase {

    func testInit() {
        let context = FSMMock.Context()
        let environment = FSMMock.Environment()
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let status: FSMStatus = .executing(transitioned: true)
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result,
            status: status
        )
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        XCTAssertEqual(fsmContext.status, status)
    }

    func testConvenienceInit() {
        let context = FSMMock.Context()
        let environment = FSMMock.Environment()
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result
        )
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        XCTAssertEqual(fsmContext.status, .executing(transitioned: true))
    }

    func testGettersAndSetters() {
        let context = FSMMock.Context()
        var context2 = context
        context2.fsmCount += 1
        let environment = FSMMock.Environment()
        var environment2 = environment
        environment2.exitActuator = true
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let result2: FSMMock.Result? = nil
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result
        )
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        fsmContext.context = context2
        XCTAssertEqual(fsmContext.context, context2)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        fsmContext.context = context
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        fsmContext.environment = environment2
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment2)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        fsmContext.environment = environment
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        fsmContext.result = result2
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result2)
    }

    func testIsFinished() {
        let fsmContext = FSMContext(
            context: FSMMock.Context(),
            environment: FSMMock.Environment(),
            parameters: FSMMock.Parameters(),
            result: FSMMock.Result(),
            status: .executing(transitioned: true)
        )
        let unfinishedCases = FSMStatus.allCases.filter { $0 != .finished }
        for currentCase in unfinishedCases {
            fsmContext.status = currentCase
            XCTAssertFalse(fsmContext.isFinished, "FSMContext.isFinished")
        }
        fsmContext.status = .finished
        XCTAssertTrue(fsmContext.isFinished, "FSMContext.isFinished")
    }

    func testIsSuspended() {
        let fsmContext = FSMContext(
            context: FSMMock.Context(),
            environment: FSMMock.Environment(),
            parameters: FSMMock.Parameters(),
            result: FSMMock.Result(),
            status: .executing(transitioned: true)
        )
        let nonsuspendedCases = FSMStatus.allCases.filter {
            $0 != .suspended(transitioned: false)
                && $0 != .suspended(transitioned: true)
        }
        for currentCase in nonsuspendedCases {
            fsmContext.status = currentCase
            XCTAssertFalse(fsmContext.isSuspended, "FSMContext.isSuspended")
        }
        fsmContext.status = .suspended(transitioned: false)
        XCTAssertTrue(fsmContext.isSuspended, "FSMContext.isSuspended")
        fsmContext.status = .suspended(transitioned: true)
        XCTAssertTrue(fsmContext.isSuspended, "FSMContext.isSuspended")
    }

    func testRestart() {
        let context = FSMMock.Context()
        let environment = FSMMock.Environment()
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result
        )
        for currentCase in FSMStatus.allCases where currentCase != .restarting {
            fsmContext.status = currentCase
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertNotEqual(fsmContext.status, .restarting)
            fsmContext.restart()
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertEqual(fsmContext.status, .restarting)
        }
        fsmContext.status = .restarting
        XCTAssertEqual(fsmContext.status, .restarting)
        fsmContext.restart()
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        XCTAssertEqual(fsmContext.status, .restarting)
    }

    func testResume() {
        let context = FSMMock.Context()
        let environment = FSMMock.Environment()
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result
        )
        for currentCase in FSMStatus.allCases where currentCase != .resuming {
            fsmContext.status = currentCase
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertNotEqual(fsmContext.status, .resuming)
            fsmContext.resume()
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertEqual(fsmContext.status, .resuming)
        }
        fsmContext.status = .resuming
        XCTAssertEqual(fsmContext.status, .resuming)
        fsmContext.resume()
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        XCTAssertEqual(fsmContext.status, .resuming)
    }

    func testSuspend() {
        let context = FSMMock.Context()
        let environment = FSMMock.Environment()
        let parameters = FSMMock.Parameters()
        let result: FSMMock.Result? = FSMMock.Result()
        let fsmContext = FSMContext(
            context: context,
            environment: environment,
            parameters: parameters,
            result: result
        )
        for currentCase in FSMStatus.allCases where currentCase != .suspending {
            fsmContext.status = currentCase
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertNotEqual(fsmContext.status, .suspending)
            fsmContext.suspend()
            XCTAssertEqual(fsmContext.context, context)
            XCTAssertEqual(fsmContext.environment, environment)
            XCTAssertEqual(fsmContext.parameters, parameters)
            XCTAssertEqual(fsmContext.result, result)
            XCTAssertEqual(fsmContext.status, .suspending)
        }
        fsmContext.status = .suspending
        XCTAssertEqual(fsmContext.status, .suspending)
        fsmContext.suspend()
        XCTAssertEqual(fsmContext.context, context)
        XCTAssertEqual(fsmContext.environment, environment)
        XCTAssertEqual(fsmContext.parameters, parameters)
        XCTAssertEqual(fsmContext.result, result)
        XCTAssertEqual(fsmContext.status, .suspending)
    }

}
