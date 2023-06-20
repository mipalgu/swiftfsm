import XCTest

@testable import FSM

// swiftlint:disable type_body_length

final class AnyTransitionTests: XCTestCase {

    struct SimpleTransition: TransitionProtocol {

        let target = false

        func canTransition(from source: Bool) -> Bool {
            source
        }

    }

    struct Root {

        var state = StateInformation(name: "State")

    }

    func testFromBase() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        XCTAssertFalse(anyTransition.target)
        XCTAssertTrue(anyTransition.canTransition(from: true))
        XCTAssertFalse(anyTransition.canTransition(from: false))
    }

    func testFromClosures() {
        let anyTransition1 = AnyTransition<Bool, Bool>(to: false) { $0 }
        XCTAssertFalse(anyTransition1.target)
        XCTAssertTrue(anyTransition1.canTransition(from: true))
        XCTAssertFalse(anyTransition1.canTransition(from: false))
        let anyTransition2 = AnyTransition<Bool, Bool>(to: true) { !$0 }
        XCTAssertTrue(anyTransition2.target)
        XCTAssertFalse(anyTransition2.canTransition(from: true))
        XCTAssertTrue(anyTransition2.canTransition(from: false))
    }

    func testFromKeyPath() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        XCTAssertEqual(root.state, transition.target(root))
        XCTAssertFalse(transition.canTransition(from: false))
        XCTAssertTrue(transition.canTransition(from: true))
    }

    func testFromTargetStateString() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        XCTAssertEqual(root.state, transition.target(root))
        XCTAssertFalse(transition.canTransition(from: false))
        XCTAssertTrue(transition.canTransition(from: true))
    }

    func testMapChangesTarget() {
        let transition1: AnyTransition<Bool, Bool> = AnyTransition(to: false) { _ in true }
        let transition2: AnyTransition<Bool, Bool> = AnyTransition(to: true) { _ in false }
        let newTransition1: AnyTransition<Bool, Int> = transition1.map { $0 ? 1 : 0 }
        let newTransition2: AnyTransition<Bool, Int> = transition2.map { $0 ? 1 : 0 }
        XCTAssertEqual(newTransition1.target, 0)
        XCTAssertEqual(newTransition1.canTransition(from: false), transition1.canTransition(from: false))
        XCTAssertEqual(newTransition1.canTransition(from: true), transition1.canTransition(from: true))
        XCTAssertEqual(newTransition2.target, 1)
        XCTAssertEqual(newTransition2.canTransition(from: false), transition2.canTransition(from: false))
        XCTAssertEqual(newTransition2.canTransition(from: true), transition2.canTransition(from: true))
    }

    func testFromBasePerformance_1() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            _ = anyTransition.canTransition(from: false)
        }
    }

    func testFromBasePerformance_10() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<10 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_100() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<100 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_1000() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<1000 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_10_000() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<10_000 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_100_000() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<100_000 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_1_000_000() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<1_000_000 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromBasePerformance_10_000_000() {
        let simpleTransition = SimpleTransition()
        let anyTransition = AnyTransition(simpleTransition)
        measure {
            for _ in 0..<10_000_000 {
                _ = anyTransition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_1() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            _ = transition.canTransition(from: false)
        }
    }

    func testFromClosuresPerformance_10() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<10 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_100() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<100 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_1000() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<1000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_10_000() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<10_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_100_000() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<100_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_1_000_000() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<1_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromClosuresPerformance_10_000_000() {
        let transition = AnyTransition<Bool, Bool>(to: false) { $0 }
        measure {
            for _ in 0..<10_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_1() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            _ = transition.canTransition(from: false)
        }
    }

    func testFromKeyPathPerformance_10() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<10 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_100() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<100 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_1000() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<1000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_10_000() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<10_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_100_000() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<100_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_1_000_000() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<1_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromKeyPathPerformance_10_000_000() {
        IDRegistrar.removeAll()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: \.state) { $0 }
        measure {
            for _ in 0..<10_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_1() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            _ = transition.canTransition(from: false)
        }
    }

    func testFromTargetStateStringPerformance_10() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<10 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_100() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<100 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_1000() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<1000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_10_000() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<10_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_100_000() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<100_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_1_000_000() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<1_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

    func testFromTargetStateStringPerformance_10_000_000() {
        IDRegistrar.removeAll()
        let root = Root()
        let transition = AnyTransition<Bool, (Root) -> StateInformation>(to: root.state.name) { $0 }
        measure {
            for _ in 0..<10_000_000 {
                _ = transition.canTransition(from: false)
            }
        }
    }

}
