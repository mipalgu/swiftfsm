import XCTest

@testable import FSM

final class DependencyTests: XCTestCase {

    func testInit() {
        let fsm = Int.random(in: 0..<Int.max)
        let dep = FSMDependency.submachine(id: 5)
        let dependency = Dependency(to: fsm, satisfying: dep)
        XCTAssertEqual(dependency.fsm, fsm)
        XCTAssertEqual(dependency.dependency, dep)
    }

    func testEquality() {
        let fsm1 = 123
        let fsm2 = 456
        let dep1 = FSMDependency.submachine(id: 5)
        let dep2 = FSMDependency.async(id: 3)
        let dependency1 = Dependency(to: fsm1, satisfying: dep1)
        let dependency2 = Dependency(to: fsm2, satisfying: dep1)
        let dependency3 = Dependency(to: fsm1, satisfying: dep2)
        let dependency4 = Dependency(to: fsm2, satisfying: dep2)
        XCTAssertEqual(dependency1, dependency1)
        XCTAssertNotEqual(dependency1, dependency2)
        XCTAssertNotEqual(dependency2, dependency1)
        XCTAssertNotEqual(dependency1, dependency3)
        XCTAssertNotEqual(dependency3, dependency1)
        XCTAssertNotEqual(dependency1, dependency4)
        XCTAssertNotEqual(dependency4, dependency1)
    }

    func testHashable() {
        let fsm1 = 123
        let fsm2 = 456
        let dep1 = FSMDependency.submachine(id: 5)
        let dep2 = FSMDependency.async(id: 3)
        let dependency1 = Dependency(to: fsm1, satisfying: dep1)
        let dependency2 = Dependency(to: fsm2, satisfying: dep1)
        let dependency3 = Dependency(to: fsm1, satisfying: dep2)
        let dependency4 = Dependency(to: fsm2, satisfying: dep2)
        var collection = Set<Dependency>()
        collection.insert(dependency1)
        XCTAssertTrue(collection.contains(dependency1), "Collection should contain dependency1")
        XCTAssertFalse(collection.contains(dependency2), "Collection should not contain dependency2")
        XCTAssertFalse(collection.contains(dependency3), "Collection should not contain dependency3")
        XCTAssertFalse(collection.contains(dependency4), "Collection should not contain dependency4")
    }

    func testCodable() throws {
        let dependency = Dependency(to: 123, satisfying: .submachine(id: 3))
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let result = try decoder.decode(Dependency.self, from: try encoder.encode(dependency))
        XCTAssertEqual(dependency, result)
    }

}
