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
    Ringlet.TransitionType == AnyTransition<
        AnyStateContext<Context, Environment, Parameters, Result>,
        StateID
    > {

    public typealias Data = FSMData<Ringlet.Context, Parameters, Result, Context, Environment>

    public typealias Handlers = FSMHandlers<Environment>

    public typealias State = FSMState<StateType, Parameters, Result, Context, Environment>

    public typealias States = StateContainer<StateType, Parameters, Result, Context, Environment>

    public let stateContainer: States

    public let ringlet: Ringlet

    public let handlers: Handlers

    public let initialState: Int

    public let initialPreviousState: Int

    public let suspendState: Int

    public var states: [State] {
        stateContainer.states
    }

    public func initialData(with parameters: Parameters) -> Data {
        let fsmContext = FSMContext(
            context: Context(),
            environment: Environment(),
            parameters: parameters,
            result: Result?.none
        )
        return FSMData(
            acceptingStates: stateContainer.states.map { $0.transitions.isEmpty },
            stateContexts: stateContainer.states.map { $0.stateType.initialContext(fsmContext: fsmContext) },
            fsmContext: fsmContext,
            ringletContext: Ringlet.Context(),
            actuatorValues: handlers.actuators.values.sorted { $0.index < $1.index }.map { $0.initialValue },
            initialState: initialState,
            currentState: initialState,
            previousState: initialPreviousState,
            suspendState: suspendState,
            suspendedState: nil
        )
    }

    init(
        stateContainer: States,
        ringlet: Ringlet,
        handlers: Handlers,
        initialState: Int,
        initialPreviousState: Int,
        suspendState: Int
    ) {
        self.stateContainer = stateContainer
        self.ringlet = ringlet
        self.handlers = handlers
        self.initialState = initialState
        self.initialPreviousState = initialPreviousState
        self.suspendState = suspendState
    }

    public func next(context: AnySchedulerContext) {
        let context = unsafeDowncast(
            context,
            to: SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.stateContainer = stateContainer
        defer { context.stateContainer = nil }
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
