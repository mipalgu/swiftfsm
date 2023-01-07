public final class FiniteStateMachine<
    StateType: TypeErasedState,
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: Executable where StateType.FSMsContext == Context,
    StateType.Environment == Environment,
    Ringlet.StateType == StateType,
    Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID> {

    public typealias Handlers = FSMHandlers<Environment>

    public typealias State = FSMState<StateType, Parameters, Result, Context, Environment>

    public typealias States = StateContainer<StateType, Parameters, Result, Context, Environment>

    public let stateContainer: States

    public let ringlet: Ringlet

    public let handlers: Handlers

    public var states: [State] {
        stateContainer.states
    }

    init(stateContainer: States, ringlet: Ringlet, handlers: Handlers) {
        self.stateContainer = stateContainer
        self.ringlet = ringlet
        self.handlers = handlers
    }

    public func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, context: AnySchedulerContext) {
        let context = unsafeDowncast(
            context,
            to: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.stateContainer = stateContainer
        defer { context.stateContainer = nil }
        context.data.fsmContext.state = context.data.stateContexts[context.currentState]
        let nextState = ringlet.execute(context: context)
        context.data.previousState = context.currentState
        context.data.currentState = nextState
        if context.data.fsmContext.status == .suspending {
            context.data.suspend()
        } else if context.data.fsmContext.status == .resuming {
            context.data.resume()
        } else if context.data.fsmContext.status == .restarting {
            context.data.restart()
        } else {
            context.data.fsmContext.status = .executing(
                transitioned: context.data.currentState != context.data.previousState
            )
        }
    }

    public func saveSnapshot(context: AnySchedulerContext) {
        let context = unsafeDowncast(
            context,
            to: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.data.saveSnapshot(
            environmentVariables: states[context.data.currentState].environmentVariables,
            handlers: handlers
        )
    }

    public func takeSnapshot(context: AnySchedulerContext) {
        let context = unsafeDowncast(
            context,
            to: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.data.takeSnapshot(
            environmentVariables: states[context.data.currentState].environmentVariables,
            handlers: handlers
        )
    }

}
