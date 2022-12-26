import XCTest

@testable import FSM

final class TransitionBuilderTests: XCTestCase {

    final class Calls {

        var calls: [String] = []

    }

    var calls: Calls = Calls()

    override func setUp() {
        self.calls = Calls()
    }

    func testOneTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 1)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 1)
    }

    func testTwoTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 2)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 2)
    }

    func testThreeTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 3)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 3)
    }

    func testFourTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 4)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 4)
    }

    func testFiveTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 5)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 5)
    }

    func testSixTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 6)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 6)
    }

    func testSevenTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 7)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 7)
    }

    func testEightTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 8)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 8)
    }

    func testNineTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 9)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 9)
    }

    func testTenTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 10)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 10)
    }

    func testElevenTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 10) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "10")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 10) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "10")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 11)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 11)
    }

    func testTwelveTransitions() {
        @TransitionBuilder
        var trueTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 10) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "10")
                return true
            }
            CallbackTransition<EmptyMockState, Int>(target: 11) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "11")
                return true
            }
        }
        @TransitionBuilder
        var falseTransitions: [AnyTransition<EmptyMockState, Int>] {
            CallbackTransition<EmptyMockState, Int>(target: 0) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "0")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 1) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "1")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 2) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "2")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 3) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "3")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 4) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "4")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 5) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "5")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 6) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "6")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 7) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "7")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 8) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "8")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 9) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "9")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 10) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "10")
                return false
            }
            CallbackTransition<EmptyMockState, Int>(target: 11) { state in
                self.calls.calls.append(state.name)
                XCTAssertEqual(state.name, "11")
                return false
            }
        }
        checkTransitions(transitions: trueTransitions, calls: calls, expectedValue: true, expectedCount: 12)
        calls.calls = []
        checkTransitions(transitions: falseTransitions, calls: calls, expectedValue: false, expectedCount: 12)
    }

    private func checkTransitions(
        transitions: [AnyTransition<EmptyMockState, Int>],
        calls: Calls,
        expectedValue: Bool,
        expectedCount: Int
    ) {
        XCTAssertEqual(transitions.count, expectedCount)
        var previousCalls = calls.calls
        for index in 0..<transitions.count {
            let state = EmptyMockState(name: "\(index)")
            XCTAssertEqual(transitions[index].target, index)
            XCTAssertEqual(transitions[index].canTransition(from: state), expectedValue)
            previousCalls += [state.name]
            XCTAssertEqual(calls.calls, previousCalls)
        }
    }

}
