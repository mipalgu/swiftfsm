import Foundation
import FSM
import XCTest

@testable import Verification

struct ExecutableMock: Executable, Identifiable, Hashable, Codable {

    var id = UUID()

    func isFinished(context _: AnySchedulerContext) -> Bool {
        true
    }

    func isSuspended(context _: AnySchedulerContext) -> Bool {
        true
    }

    func next(context _: AnySchedulerContext) {}

    func saveSnapshot(context _: AnySchedulerContext) {}

    func takeSnapshot(context _: AnySchedulerContext) {}

}

final class ExecutableTypeTests: XCTestCase {

    func testExecutableTypeReturnsTheUnderlyingExecutable() {
        let mock = ExecutableMock()
        let type = ExecutableType.controllable(mock)
        let executable = type.executable as? ExecutableMock
        XCTAssertNotNil(executable)
        XCTAssertEqual(mock, executable)
    }

}
