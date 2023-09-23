import FSM
import XCTest

@testable import Verification

final class ExectuablePoolTests: XCTestCase {

    let startingMocks: [(FSMInformation, ExecutableMock)] = [
        (FSMInformation(id: 0, name: "exe0", dependencies: []), ExecutableMock()),
        (FSMInformation(id: 1, name: "exe1", dependencies: []), ExecutableMock()),
        (FSMInformation(id: 2, name: "exe2", dependencies: []), ExecutableMock()),
    ]

    var pool = ExecutablePool(executables: [])

    override func setUp() {
        self.pool = ExecutablePool(executables: startingMocks.map {
            ($0, ExecutableType.controllable($1))
        })
    }

    func testInitResortsElements() {
        let newStartingMocks = startingMocks.sorted { $0.0.id > $1.0.id }
        pool = ExecutablePool(executables: newStartingMocks.map {
            ($0, ExecutableType.controllable($1))
        })
        let expectedMocks = startingMocks.map(\.1)
        XCTAssertEqual(expectedMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        for _ in 0..<10 {
            pool = ExecutablePool(executables: startingMocks.shuffled().map {
                ($0, ExecutableType.controllable($1))
            })
            XCTAssertEqual(expectedMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        }
    }

    func testInsertReplacesElements() {
        let existingMockInformation = startingMocks[2].0
        let newMock = ExecutableMock()
        var currentMocks = startingMocks.map(\.1)
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        pool.insert(.controllable(newMock), information: existingMockInformation)
        currentMocks[2] = newMock
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
    }

    func testInsertAddsElements() {
        let newMockInformation = FSMInformation(id: 3, name: "exe3", dependencies: [])
        let newMock = ExecutableMock()
        var currentMocks = startingMocks.map(\.1)
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        pool.insert(.controllable(newMock), information: newMockInformation)
        currentMocks.append(newMock)
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
    }

    func testHasFindsElementsThatExist() {
        XCTAssertTrue(pool.has(0), "has(_: ExecutableID) cannot find executable with id 0.")
    }

    func testHasCannotFindElementThatDoesNotExist() {
        XCTAssertFalse(
            pool.has(3),
            "has(_: ExecutableID) found an executable with id 3 that should not exist."
        )
    }

    func testHasThatIsntDelegateFindsElementsThatExist() {
        XCTAssertTrue(pool.hasThatIsntDelegate(0), "has(_: ExecutableID) cannot find executable with id 0.")
    }

    func testHasThatIsntDelegateCannotFindElementThatDoesNotExist() {
        XCTAssertFalse(
            pool.hasThatIsntDelegate(3),
            "has(_: ExecutableID) found an executable with id 3 that should not exist."
        )
    }

    func testIndexFindsElementsWithCorrectIds() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (expectedIndex, (info, _)) in startingMocks.enumerated() {
            XCTAssertEqual(expectedIndex, pool.index(of: info.id), "Invalid index of mock with id \(info.id)")
        }
    }

    func testExecutableFetchesMocksWithCorrectIndexes() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (index, (_, mock)) in startingMocks.enumerated() {
            let fetchedMock = pool.executable(atIndex: index).executable as? ExecutableMock
            XCTAssertNotNil(fetchedMock)
            XCTAssertEqual(mock, fetchedMock, "Unexpected mock at index \(index).")
        }
    }

    func testExecutableFetchesMocksWithCorrectIds() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (info, mock) in startingMocks {
            let fetchedMock = pool.executable(info.id).executable as? ExecutableMock
            XCTAssertNotNil(fetchedMock)
            XCTAssertEqual(mock, fetchedMock, "Unexpected mock with id \(info.id).")
        }
    }

}
