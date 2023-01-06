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
        id: StateID,
        state: AnyLLFSMState<FSMsContext, Environment, Parameters, Result>,
        transitions: [AnyTransition<FSMContext<FSMsContext, Environment, Parameters, Result>, StateID>],
        context: RingletContext<Context, FSMsContext, Environment, Parameters, Result>
    ) -> StateID {
        if case .resumed = context.fsmContext.status {
            state.onResume(context: context.fsmContext)
        }
        if context.fsmContext.status.transitioned {
            state.onEntry(context: context.fsmContext)
        }
        let result: StateID
        if let first = transitions.first(where: { $0.canTransition(from: context.fsmContext) }) {
            state.onExit(context: context.fsmContext)
            result = first.target
        } else {
            state.internal(context: context.fsmContext)
            result = id
        }
        if context.fsmContext.status == .suspending {
            state.onSuspend(context: context.fsmContext)
        }
        return result
    }

}
