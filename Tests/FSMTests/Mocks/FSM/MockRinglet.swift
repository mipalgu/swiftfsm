import FSM

struct MockRinglet<FSMsContext: DataStructure, Environment: EnvironmentSnapshot>: RingletProtocol {

    typealias StateType = AnyMockState<FSMsContext, Environment>
    typealias TransitionType = AnyTransition<FSMContext<FSMsContext, Environment>, StateID>

    func execute(
        id: StateID,
        state: AnyMockState<FSMsContext, Environment>,
        transitions: [AnyTransition<FSMContext<FSMsContext, Environment>, StateID>],
        fsmContext: inout FSMContext<FSMsContext, Environment>,
        context: inout Context
    ) -> StateID {
        if case .resumed = fsmContext.status {
            state.onResume(context: &fsmContext)
        }
        if fsmContext.status.transitioned {
            state.onEntry(context: &fsmContext)
        }
        let result: StateID
        if let first = transitions.first(where: { $0.canTransition(from: fsmContext) }) {
            state.onExit(context: &fsmContext)
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
