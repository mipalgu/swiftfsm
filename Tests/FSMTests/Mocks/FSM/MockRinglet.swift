import FSM

struct MockRinglet<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: RingletProtocol {

    typealias StateType = AnyMockState<FSMsContext, Environment, Parameters, Result>
    typealias TransitionType = AnyTransition<FSMContext<FSMsContext, Environment, Parameters, Result>, StateID>

    func execute(
        id: StateID,
        state: AnyMockState<FSMsContext, Environment, Parameters, Result>,
        transitions: [AnyTransition<FSMContext<FSMsContext, Environment, Parameters, Result>, StateID>],
        fsmContext: inout FSMContext<FSMsContext, Environment, Parameters, Result>,
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
