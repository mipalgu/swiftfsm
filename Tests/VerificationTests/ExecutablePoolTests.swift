import FSM
import LLFSMs
import XCTest

@testable import Verification

final class ExectuablePoolTests: XCTestCase {

    let timeslots = [
        Timeslot(
            executables: [0],
            callChain: CallChain(root: 0, calls: []),
            startingTime: 10,
            duration: 30,
            cyclesExecuted: 0
        ),
        Timeslot(
            executables: [1],
            callChain: CallChain(root: 1, calls: []),
            startingTime: 50,
            duration: 15,
            cyclesExecuted: 0
        ),
        Timeslot(
            executables: [2],
            callChain: CallChain(root: 2, calls: []),
            startingTime: 80,
            duration: 5,
            cyclesExecuted: 0
        )
    ]

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

    func testContextFetchesMocksWithCorrectIndexes() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (index, (_, (context, _))) in startingMocks.enumerated() {
            let fetchedContext = pool.context(atIndex: index)
            XCTAssertIdentical(context, fetchedContext, "Unexpected context at index \(index).")
        }
    }

    func testContextFetchesMocksWithCorrectIds() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (info, (context, _)) in startingMocks {
            let fetchedContext = pool.context(info.id)
            XCTAssertIdentical(context, fetchedContext, "Unexpected context with id \(info.id).")
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

    func testCloneCreatesNewContexts() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (index, (_, (context, _))) in startingMocks.enumerated() {
            let fetchedContext = pool.cloned.context(atIndex: index)
            XCTAssertNotIdentical(context, fetchedContext, "Unexpected context at index \(index).")
        }
    }

    func testCloneCreatesTheSameMocks() {
        XCTAssertFalse(startingMocks.isEmpty, "startingMocks should not be empty.")
        for (index, (_, (_, mock))) in startingMocks.enumerated() {
            let fetchedMock = pool.cloned.executable(atIndex: index).executable as? ExecutableMock
            XCTAssertNotNil(fetchedMock)
            XCTAssertEqual(mock, fetchedMock, "Unexpected mock at index \(index).")
        }
    }

    func testPropertyList() {
        let model = EmptyMachine()
        let info = FSMInformation(fsm: model)
        let (executable, contextFactory) = model.initial(
            actuators: [],
            externalVariables: [],
            globalVariables: [],
            sensors: []
        )
        let context = contextFactory(nil)
        let pool = ExecutablePool(executables: [(info, (context, .controllable(executable)))])
        let timeslot = Timeslot(
            executables: [info.id],
            callChain: CallChain(root: info.id, calls: []),
            startingTime: 0,
            duration: 30,
            cyclesExecuted: 0
        )
        let plist = pool.propertyList(
            forStep: .takeSnapshotAndStartTimeslot(timeslot: timeslot),
            executingState: "Exit",
            resetClocks: [0],
            collapseIfPossible: true
        )
        XCTAssertNotNil(plist.properties["fsms"])
        XCTAssertNotNil(plist.properties["pc"])
    }

}
