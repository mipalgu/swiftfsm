import XCTest

@testable import Verification

final class ExecutableTypeTests: XCTestCase {

    func testExecutableTypeReturnsTheUnderlyingExecutable() {
        let mock = ExecutableMock()
        let type = ExecutableType.controllable(mock)
        let executable = type.executable as? ExecutableMock
        XCTAssertNotNil(executable)
        XCTAssertEqual(mock, executable)
    }

}
