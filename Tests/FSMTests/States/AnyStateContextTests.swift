import XCTest

@testable import FSM

final class AnyStateContextTests: XCTestCase {

    func testInit() {
        let fsmContext = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let stateContext = AnyStateContext(fsmContext: fsmContext)
        XCTAssertIdentical(stateContext.fsmContext, fsmContext)
    }

}
