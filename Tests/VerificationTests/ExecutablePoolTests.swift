import FSM
import LLFSMs
import XCTest

@testable import Verification

final class ExectuablePoolTests: XCTestCase {

    let startingMocks: [(FSMInformation, (AnySchedulerContext, ExecutableMock))] = {
        let exe0Context = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: Optional<EmptyDataStructure>.none
        )
        let exe1Context = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: Optional<EmptyDataStructure>.none
        )
        let exe2Context = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: Optional<EmptyDataStructure>.none
        )
        return [
            (
                FSMInformation(id: 0, name: "exe0", dependencies: []),
                (
                    SchedulerContext<
                        AnyLLFSMState<
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure
                        >,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure
                    >(
                        fsmID: 0,
                        fsmName: "exe0",
                        data: FSMData(
                            acceptingStates: [true],
                            stateContexts: [
                                StateContext(context: EmptyDataStructure(), fsmContext: exe0Context)
                            ],
                            fsmContext: exe0Context,
                            ringletContext: EmptyDataStructure(),
                            actuatorValues: [],
                            initialState: 0,
                            currentState: 0,
                            previousState: 0,
                            suspendState: 0,
                            suspendedState: nil
                        )
                    ),
                    ExecutableMock()
                )
            ),
            (
                FSMInformation(id: 1, name: "exe1", dependencies: []),
                (
                    SchedulerContext<
                        AnyLLFSMState<
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure
                        >,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure
                    >(
                        fsmID: 1,
                        fsmName: "exe1",
                        data: FSMData(
                            acceptingStates: [true],
                            stateContexts: [
                                StateContext(context: EmptyDataStructure(), fsmContext: exe1Context)
                            ],
                            fsmContext: exe1Context,
                            ringletContext: EmptyDataStructure(),
                            actuatorValues: [],
                            initialState: 0,
                            currentState: 0,
                            previousState: 0,
                            suspendState: 0,
                            suspendedState: nil
                        )
                    ),
                    ExecutableMock()
                )
            ),
            (
                FSMInformation(id: 2, name: "exe2", dependencies: []),
                (
                    SchedulerContext<
                        AnyLLFSMState<
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure,
                            EmptyDataStructure
                        >,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure,
                        EmptyDataStructure
                    >(
                        fsmID: 2,
                        fsmName: "exe2",
                        data: FSMData(
                            acceptingStates: [true],
                            stateContexts: [
                                StateContext(context: EmptyDataStructure(), fsmContext: exe2Context)
                            ],
                            fsmContext: exe2Context,
                            ringletContext: EmptyDataStructure(),
                            actuatorValues: [],
                            initialState: 0,
                            currentState: 0,
                            previousState: 0,
                            suspendState: 0,
                            suspendedState: nil
                        )
                    ),
                    ExecutableMock()
                )
            ),
        ]
    }()

    var pool = ExecutablePool(executables: [])

    override func setUp() {
        self.pool = ExecutablePool(executables: startingMocks.map {
            ($0, ($1.0, ExecutableType.controllable($1.1)))
        })
    }

    func testInitResortsElements() {
        let newStartingMocks = startingMocks.sorted { $0.0.id > $1.0.id }
        pool = ExecutablePool(executables: newStartingMocks.map {
            ($0, ($1.0, ExecutableType.controllable($1.1)))
        })
        let expectedMocks = startingMocks.map(\.1.1)
        XCTAssertEqual(expectedMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        for _ in 0..<10 {
            pool = ExecutablePool(executables: startingMocks.shuffled().map {
                ($0, ($1.0, ExecutableType.controllable($1.1)))
            })
            XCTAssertEqual(expectedMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        }
    }

    func testInsertReplacesElements() {
        let existingMockInformation = startingMocks[2].0
        let exe3Context = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: Optional<EmptyDataStructure>.none
        )
        let newContext = SchedulerContext<
            AnyLLFSMState<
                EmptyDataStructure,
                EmptyDataStructure,
                EmptyDataStructure,
                EmptyDataStructure
            >,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >(
            fsmID: 3,
            fsmName: "exe3",
            data: FSMData(
                acceptingStates: [true],
                stateContexts: [
                    StateContext(context: EmptyDataStructure(), fsmContext: exe3Context)
                ],
                fsmContext: exe3Context,
                ringletContext: EmptyDataStructure(),
                actuatorValues: [],
                initialState: 0,
                currentState: 0,
                previousState: 0,
                suspendState: 0,
                suspendedState: nil
            )
        )
        let newMock = ExecutableMock()
        var currentMocks = startingMocks.map(\.1.1)
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        pool.insert(.controllable(newMock), context: newContext, information: existingMockInformation)
        currentMocks[2] = newMock
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
    }

    func testInsertAddsElements() {
        let newMockInformation = FSMInformation(id: 3, name: "exe3", dependencies: [])
        let exe3Context = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: Optional<EmptyDataStructure>.none
        )
        let newContext = SchedulerContext<
            AnyLLFSMState<
                EmptyDataStructure,
                EmptyDataStructure,
                EmptyDataStructure,
                EmptyDataStructure
            >,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >(
            fsmID: 3,
            fsmName: "exe3",
            data: FSMData(
                acceptingStates: [true],
                stateContexts: [
                    StateContext(context: EmptyDataStructure(), fsmContext: exe3Context)
                ],
                fsmContext: exe3Context,
                ringletContext: EmptyDataStructure(),
                actuatorValues: [],
                initialState: 0,
                currentState: 0,
                previousState: 0,
                suspendState: 0,
                suspendedState: nil
            )
        )
        let newMock = ExecutableMock()
        var currentMocks = startingMocks.map(\.1.1)
        XCTAssertEqual(currentMocks, pool.executables.compactMap { $0.executable as? ExecutableMock })
        pool.insert(.controllable(newMock), context: newContext, information: newMockInformation)
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
        for (index, (_, (_, mock))) in startingMocks.enumerated() {
            let fetchedMock = pool.executable(atIndex: index).executable as? ExecutableMock
            XCTAssertNotNil(fetchedMock)
            XCTAssertEqual(mock, fetchedMock, "Unexpected mock at index \(index).")
        }
    }

    func testExecutableFetchesMocksWithCorrectIds() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (info, (_, mock)) in startingMocks {
            let fetchedMock = pool.executable(info.id).executable as? ExecutableMock
            XCTAssertNotNil(fetchedMock)
            XCTAssertEqual(mock, fetchedMock, "Unexpected mock with id \(info.id).")
        }
    }

}
