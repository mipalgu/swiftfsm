import FSM
import XCTest

@testable import Verification

final class CallTests: XCTestCase {

    let caller = FSMInformation(id: 0, name: "exe0", dependencies: [.sync(id: 1)])

    let callee = FSMInformation(id: 1, name: "exe1", dependencies: [])

    let parameters: [Int: (any DataStructure)?] = [
        0: 3,
        1: "hello"
    ]

    let method: Call.Method = .synchronous

    var call: Call!

    override func setUp() {
        self.call = Call(caller: caller, callee: callee, parameters: parameters, method: method)
    }

    func testInit() {
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
    }

    func testGettersAndSetters() {
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        let newCaller = FSMInformation(id: 2, name: "exe2", dependencies: [.async(id: 4)])
        call.caller = newCaller
        XCTAssertEqual(newCaller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        call.caller = caller
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        let newCallee = FSMInformation(id: 3, name: "exe3", dependencies: [])
        call.callee = newCallee
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(newCallee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        call.callee = callee
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        let newParameters: [Int: (any DataStructure)?] = [
            3: false,
            4: 1.2
        ]
        call.parameters = newParameters
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[3] as? Bool)
        XCTAssertEqual(newParameters[3] as? Bool, call.parameters[3] as? Bool)
        XCTAssertNotNil(call.parameters[4] as? Double)
        XCTAssertEqual(newParameters[4] as? Double, call.parameters[4] as? Double)
        XCTAssertEqual(method, call.method)
        call.parameters = parameters
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
        let newMethod: Call.Method = .asynchronous
        call.method = newMethod
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(newMethod, call.method)
        call.method = method
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        XCTAssertEqual(method, call.method)
    }

    func testEquality() {
        XCTAssertEqual(caller, call.caller)
        XCTAssertEqual(callee, call.callee)
        XCTAssertNotNil(call.parameters[0] as? Int)
        XCTAssertEqual(parameters[0] as? Int, call.parameters[0] as? Int)
        XCTAssertNotNil(call.parameters[1] as? String)
        XCTAssertEqual(parameters[1] as? String, call.parameters[1] as? String)
        let other = call
        XCTAssertEqual(call, other)
        let newCaller = FSMInformation(id: 2, name: "exe2", dependencies: [.async(id: 4)])
        call.caller = newCaller
        XCTAssertNotEqual(call, other)
        call.caller = caller
        XCTAssertEqual(call, other)
        let newCallee = FSMInformation(id: 3, name: "exe3", dependencies: [])
        call.callee = newCallee
        XCTAssertNotEqual(call, other)
        call.callee = callee
        XCTAssertEqual(call, other)
        let newParameters: [Int: (any DataStructure)?] = [
            3: false,
            4: 1.2
        ]
        call.parameters = newParameters
        XCTAssertNotEqual(call, other)
        call.parameters = parameters
        XCTAssertEqual(call, other)
        let newMethod: Call.Method = .asynchronous
        call.method = newMethod
        XCTAssertNotEqual(call, other)
        call.method = method
        XCTAssertEqual(call, other)
    }

    func testHashable() {
        guard let other = call else {
            XCTFail("Unable to fetch call.")
            return
        }
        var collection: Set<Call> = []
        XCTAssertFalse(collection.contains(call))
        XCTAssertFalse(collection.contains(other))
        collection.insert(call)
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        let newCaller = FSMInformation(id: 2, name: "exe2", dependencies: [.async(id: 4)])
        call.caller = newCaller
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.insert(call)
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.remove(call)
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        call.caller = caller
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        let newCallee = FSMInformation(id: 3, name: "exe3", dependencies: [])
        call.callee = newCallee
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.insert(call)
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.remove(call)
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        call.callee = callee
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        let newParameters: [Int: (any DataStructure)?] = [
            3: false,
            4: 1.2
        ]
        call.parameters = newParameters
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.insert(call)
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.remove(call)
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        call.parameters = parameters
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        let newMethod: Call.Method = .asynchronous
        call.method = newMethod
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.insert(call)
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        collection.remove(call)
        XCTAssertFalse(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
        call.method = method
        XCTAssertTrue(collection.contains(call))
        XCTAssertTrue(collection.contains(other))
    }

}
