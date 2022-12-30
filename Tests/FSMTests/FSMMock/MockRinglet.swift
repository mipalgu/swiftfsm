import FSM

struct MockRinglet<FSMsContext: DataStructure, Environment: EnvironmentSnapshot>: RingletProtocol {

    typealias StateType = AnyMockState<FSMsContext, Environment>
    typealias TransitionType = AnyTransition<FSMContext<FSMsContext, Environment>, StateID>

    struct Context: DataStructure, EmptyInitialisable {

        var shouldExecuteOnEntry: Bool = true

    }

    func execute(
        id: StateID,
        state: AnyMockState<FSMsContext, Environment>,
        transitions: [AnyTransition<FSMContext<FSMsContext, Environment>, StateID>],
        fsmContext: inout FSMContext<FSMsContext, Environment>,
        context: inout Context
    ) -> StateID {
        if fsmContext.status == .resuming {
            state.onResume(context: &fsmContext)
        }
        if context.shouldExecuteOnEntry {
            state.onEntry(context: &fsmContext)
        }
        let result: StateID
        if let first = transitions.first(where: { $0.canTransition(from: fsmContext) }) {
            state.onExit(context: &fsmContext)
            context.shouldExecuteOnEntry = true
            result = first.target
        } else {
            state.internal(context: &fsmContext)
            result = id
        }
        if fsmContext.status == .suspending {
            state.onSuspend(context: &fsmContext)
        }
        return result
    }

}
