import FSM

public struct LLFSMRinglet<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: RingletProtocol {

    public typealias StateType = AnyLLFSMState<FSMsContext, Environment, Parameters, Result>
    public typealias TransitionType = AnyTransition<
        AnyStateContext<FSMsContext, Environment, Parameters, Result>, StateID
    >

    public init() {}

    public func execute(
        context: SchedulerContext<StateType, Context, FSMsContext, Environment, Parameters, Result>
    ) -> StateID {
        let state = context.states[context.currentState]
        let stateContext = context.context(forState: context.currentState)
        let suspendState = context.states[context.suspendState].stateType
        let suspendStateContext = context.context(forState: context.suspendState)
        if case .resumed = context.status {
            if context.currentState != context.suspendState {
                suspendState.onResume(context: suspendStateContext)
            }
            state.stateType.onResume(context: stateContext)
        }
        if context.status.transitioned {
            state.stateType.onEntry(context: stateContext)
        }
        let result: StateID
        if let first = state.transitions.first(where: { $0.canTransition(from: stateContext) }) {
            state.stateType.onExit(context: stateContext)
            result = first.target
        } else {
            state.stateType.internal(context: stateContext)
            result = context.currentState
        }
        if context.fsmContext.status == .suspending {
            state.stateType.onSuspend(context: stateContext)
            if context.currentState != context.suspendState {
                suspendState.onSuspend(context: suspendStateContext)
            }
        }
        return result
    }

}
