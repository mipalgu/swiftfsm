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
        _ = AnyStateContext(fsmContext: fsmContext)
    }

}
