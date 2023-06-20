import FSM
import Mocks
import XCTest

@testable import Model

final class SingleMachineArrangementTests: XCTestCase {

    func testInit() {
        let fsm = FSMMock()
        let arrangement = SingleMachineArrangement(fsm: fsm)
        XCTAssertEqual(arrangement.fsms.count, 1)
        guard arrangement.fsms.count == 1 else { return }
        let machine = arrangement.fsms[0]
        let id = IDRegistrar.id(of: fsm.name)
        let name = fsm.name
        let dependencies = fsm.dependencies
        let expectedInfo = FSMInformation(id: id, name: name, dependencies: dependencies)
        XCTAssertEqual(machine.projectedValue, expectedInfo)
    }

}
