import FSM
import XCTest

@testable import Verification

final class CallChainTests: XCTestCase {

    let exe0 = FSMInformation(id: 0, name: "exe0", dependencies: [])

    let exe1 = FSMInformation(id: 1, name: "exe1", dependencies: [])

    let exe2 = FSMInformation(id: 2, name: "exe2", dependencies: [])

    let exe3 = FSMInformation(id: 3, name: "exe3", dependencies: [])

    let root = 1

    let calls: [Call] = [
        Call(
            caller: FSMInformation(id: 1, name: "exe1", dependencies: []),
            callee: FSMInformation(id: 0, name: "exe0", dependencies: []),
            parameters: [:],
            method: .synchronous
        ),
        Call(
            caller: FSMInformation(id: 0, name: "exe0", dependencies: []),
            callee: FSMInformation(id: 2, name: "exe2", dependencies: []),
            parameters: [:],
            method: .synchronous
        ),
    ]

    var callChain: CallChain!

    override func setUp() {
        callChain = CallChain(root: exe1.id, calls: calls)
    }

    func testInit() {
        XCTAssertEqual(exe1.id, callChain.root)
        XCTAssertEqual(calls, callChain.calls)
    }

    func testGettersAndSetters() {
        XCTAssertEqual(exe1.id, callChain.root)
        XCTAssertEqual(calls, callChain.calls)
        let newRoot = exe2.id
        callChain.root = newRoot
        XCTAssertEqual(exe2.id, callChain.root)
        XCTAssertEqual(calls, callChain.calls)
    }

    func testEquality() {
        let other = callChain
        XCTAssertEqual(callChain, other)
        let newRoot = exe2.id
        callChain.root = newRoot
        XCTAssertNotEqual(callChain, other)
        callChain.root = root
        XCTAssertEqual(callChain, other)
        let poppedCall = callChain.pop()
        let newCall = Call(
            caller: poppedCall.caller,
            callee: poppedCall.callee,
            parameters: [12 : "newParameter"],
            method: .synchronous
        )
        XCTAssertNotEqual(callChain, other)
        callChain.add(newCall)
        XCTAssertNotEqual(callChain, other)
        callChain.pop()
        callChain.add(poppedCall)
        XCTAssertEqual(callChain, other)
    }

    func testHashable() {
        guard let other = callChain else {
            XCTFail("Unable to fetch callChain.")
            return
        }
        var collection: Set<CallChain> = []
        XCTAssertFalse(collection.contains(callChain), "Expected collection to not contain callChain.")
        XCTAssertFalse(collection.contains(other), "Expected collection to not contain other.")
        collection.insert(other)
        XCTAssertTrue(collection.contains(callChain), "Expected collection to contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
        let newRoot = exe2.id
        callChain.root = newRoot
        XCTAssertFalse(collection.contains(callChain), "Expected collection to not contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
        callChain.root = root
        XCTAssertTrue(collection.contains(callChain), "Expected collection to contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
        let poppedCall = callChain.pop()
        XCTAssertFalse(collection.contains(callChain), "Expected collection to not contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
        collection.insert(callChain)
        XCTAssertTrue(collection.contains(callChain), "Expected collection to contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
        callChain.add(poppedCall)
        XCTAssertTrue(collection.contains(callChain), "Expected collection to contain callChain.")
        XCTAssertTrue(collection.contains(other), "Expected collection to contain other.")
    }

    func testExecutableGetter() {
        XCTAssertEqual(exe2.id, callChain.executable)
        let emptyCallChain = CallChain(root: exe0.id, calls: [])
        XCTAssertEqual(exe0.id, emptyCallChain.executable)
    }

    func testAdd() {
        XCTAssertEqual(calls, callChain.calls)
        let newCall = Call(caller: exe2, callee: exe3, parameters: [:], method: .synchronous)
        callChain.add(newCall)
        XCTAssertEqual(calls + [newCall], callChain.calls)
    }

    func testPop() {
        XCTAssertEqual(calls, callChain.calls)
        XCTAssertFalse(calls.isEmpty, "Expected calls to be not empty.")
        var currentCalls = calls
        for _ in 0..<calls.count {
            let poppedCall = callChain.pop()
            let removedCall = currentCalls.removeLast()
            XCTAssertEqual(removedCall, poppedCall)
            XCTAssertEqual(currentCalls, callChain.calls)
        }
    }

    func testExecutableFromPoolWithCallsMade() {
        let executables = [
            (exe0, ExecutableMock()),
            (exe1, ExecutableMock()),
            (exe2, ExecutableMock()),
            (exe3, ExecutableMock()),
        ]
        let pool = ExecutablePool(executables: executables.map { ($0, .controllable($1)) })
        let fetchedExe = callChain.executable(fromPool: pool)
        XCTAssertEqual(executables[2].1, fetchedExe.executable as? ExecutableMock)
    }

    func testExecutableFromPoolNoCallsMade() {
        let executables = [
            (exe0, ExecutableMock()),
            (exe1, ExecutableMock()),
            (exe2, ExecutableMock()),
            (exe3, ExecutableMock()),
        ]
        let pool = ExecutablePool(executables: executables.map { ($0, .controllable($1)) })
        let emptyCallChain = CallChain(root: exe1.id, calls: [])
        let fetchedExe = emptyCallChain.executable(fromPool: pool)
        XCTAssertEqual(executables[1].1, fetchedExe.executable as? ExecutableMock)
    }

}
