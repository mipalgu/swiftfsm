import InMemoryVariables
import Model
import XCTest

@testable import FSM
@testable import LLFSMs

final class LLFSMRingletTests: XCTestCase {

    typealias Ringlet =
        LLFSMRinglet<EmptyDataStructure, EmptyDataStructure, EmptyDataStructure, EmptyDataStructure>

    typealias Transition =
        AnyTransition<
            AnyStateContext<EmptyDataStructure, EmptyDataStructure, EmptyDataStructure, EmptyDataStructure>,
            StateID
        >

    typealias TypeErasedState =
         AnyLLFSMState<EmptyDataStructure, EmptyDataStructure, EmptyDataStructure, EmptyDataStructure>

    typealias EmptyState =
        EmptyLLFSMState<EmptyDataStructure, EmptyDataStructure, EmptyDataStructure, EmptyDataStructure>

    typealias CustomFSMData =
        FSMData<
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >

    typealias CustomAnyStateContext =
        AnyStateContext<
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >

    typealias CustomSchedulerContext =
        SchedulerContext<
            TypeErasedState,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >

    typealias CustomStateContainer =
        StateContainer<
            TypeErasedState,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure,
            EmptyDataStructure
        >

    func createContext(numberOfTransitions count: Int) -> (CustomSchedulerContext, CustomStateContainer) {
        let transitions = Array(repeating: Transition(to: 0) { _ in false }, count: max(count - 1, 0))
        let state = FSMState(
            information: StateInformation(id: 0, name: "state"),
            stateType: EmptyState().erased,
            transitions: transitions + (count > 0 ? [Transition(to: 0) { _ in true }] : []),
            takeSnapshot: { _, _, _ in },
            saveSnapshot: { _, _, _ in }
        )
        let suspendState = FSMState(
            information: StateInformation(id: 1, name: "suspend"),
            stateType: EmptyState().erased,
            transitions: [Transition](),
            takeSnapshot: { _, _, _ in },
            saveSnapshot: { _, _, _ in }
        )
        let fsmContext = FSMContext(
            context: EmptyDataStructure(),
            environment: EmptyDataStructure(),
            parameters: EmptyDataStructure(),
            result: EmptyDataStructure?.none
        )
        let context = CustomSchedulerContext(
            fsmID: 0,
            fsmName: "fsm",
            data: CustomFSMData(
                acceptingStates: [false, false],
                stateContexts: [
                    StateContext(context: EmptyDataStructure(), fsmContext: fsmContext),
                    StateContext(context: EmptyDataStructure(), fsmContext: fsmContext)
                ],
                fsmContext: fsmContext,
                ringletContext: EmptyDataStructure(),
                actuatorValues: [],
                initialState: 0,
                currentState: 0,
                previousState: 1,
                suspendState: 1,
                suspendedState: nil
            )
        )
        let stateContainer = CustomStateContainer(states: [state, suspendState])
        context.stateContainer = stateContainer
        return (context, stateContainer)
    }

    func test_ringletPerformance0() {
        let (context, container) = createContext(numberOfTransitions: 0)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

    func test_ringletPerformance10() {
        let (context, container) = createContext(numberOfTransitions: 10)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

    func test_ringletPerformance100() {
        let (context, container) = createContext(numberOfTransitions: 100)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

    func test_ringletPerformance1000() {
        let (context, container) = createContext(numberOfTransitions: 1000)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

    func test_ringletPerformance10_000() {
        let (context, container) = createContext(numberOfTransitions: 10_000)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

    func test_ringletPerformance100_000() {
        let (context, container) = createContext(numberOfTransitions: 100_000)
        XCTAssertFalse(container.states.isEmpty)
        let ringlet = Ringlet()
        measure {
            _ = ringlet.execute(context: context)
        }
    }

}
