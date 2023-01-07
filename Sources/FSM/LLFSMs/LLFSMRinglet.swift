public struct LLFSMRinglet<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: RingletProtocol {

    public typealias StateType = AnyLLFSMState<FSMsContext, Environment, Parameters, Result>
    public typealias TransitionType
        = AnyTransition<FSMContext<FSMsContext, Environment, Parameters, Result>, StateID>

    public init() {}

    public func execute(
        context: SchedulerContext<StateType, Context, FSMsContext, Environment, Parameters, Result>
    ) -> StateID {
        let state = context.states[context.currentState]
        let suspendState = context.states[context.suspendState].stateType
        if case .resumed = context.status {
            if context.currentState != context.suspendState {
                suspendState.onResume(context: context.fsmContext)
            }
            state.stateType.onResume(context: context.fsmContext)
        }
        if context.status.transitioned {
            state.stateType.onEntry(context: context.fsmContext)
        }
        let result: StateID
        if let first = state.transitions.first(where: { $0.canTransition(from: context.fsmContext) }) {
            state.stateType.onExit(context: context.fsmContext)
            result = first.target
        } else {
            state.stateType.internal(context: context.fsmContext)
            result = context.currentState
        }
        if context.fsmContext.status == .suspending {
            state.stateType.onSuspend(context: context.fsmContext)
            if context.currentState != context.suspendState {
                suspendState.onSuspend(context: context.fsmContext)
            }
        }
        return result
    }

}
