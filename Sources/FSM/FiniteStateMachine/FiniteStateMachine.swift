public final class FiniteStateMachine<
    StateType: TypeErasedState,
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: Executable
where
    StateType.FSMsContext == Context,
    StateType.Environment == Environment,
    Ringlet.StateType == StateType,
    Ringlet.TransitionType == AnyTransition<
        AnyStateContext<Context, Environment, Parameters, Result>,
        StateID
    >
{

    public typealias Data = FSMData<Ringlet.Context, Parameters, Result, Context, Environment>

    public typealias Handlers = FSMHandlers<Environment>

    public typealias State = FSMState<StateType, Parameters, Result, Context, Environment>

    public typealias States = UnsafePointer<State>

    public let initialContext: Context

    public let initialRingletContext: Ringlet.Context

    public let states: States

    public let statesCount: Int

    public let ringlet: Ringlet

    public let handlers: Handlers

    public let initialState: Int

    public let initialPreviousState: Int

    public let suspendState: Int

    public func initialData(
        with parameters: Parameters,
        acceptingStates: UnsafeMutablePointer<Bool>,
        stateContexts: UnsafeMutablePointer<AnyStateContext<Context, Environment, Parameters, Result>>,
        actuatorValues: UnsafeMutablePointer<Sendable>
    ) -> Data {
        let fsmContext = FSMContext(
            context: initialContext,
            environment: Environment(),
            parameters: parameters,
            result: Result?.none
        )
        for i in 0..<statesCount {
            acceptingStates.advanced(by: i).initialize(to: states[i].transitions.isEmpty)
            stateContexts.advanced(by: i).initialize(
                to: states[i].stateType.initialContext(fsmContext: fsmContext)
            )
        }
        for i in 0..<handlers.actuators.count {
            actuatorValues.advanced(by: i).initialize(to: handlers.actuators[i].initialValue)
        }
        return FSMData(
            acceptingStates: acceptingStates,
            stateContexts: UnsafePointer(stateContexts),
            fsmContext: fsmContext,
            ringletContext: initialRingletContext,
            actuatorValues: actuatorValues,
            initialState: initialState,
            currentState: initialState,
            previousState: initialPreviousState,
            suspendState: suspendState,
            suspendedState: nil
        )
    }

    public init(
        states: States,
        statesCount: Int,
        ringlet: Ringlet,
        handlers: Handlers,
        initialContext: Context,
        initialRingletContext: Ringlet.Context,
        initialState: Int,
        initialPreviousState: Int,
        suspendState: Int
    ) {
        self.states = states
        self.statesCount = statesCount
        self.ringlet = ringlet
        self.handlers = handlers
        self.initialContext = initialContext
        self.initialRingletContext = initialRingletContext
        self.initialState = initialState
        self.initialPreviousState = initialPreviousState
        self.suspendState = suspendState
    }

    public func isFinished(context: UnsafePointer<SchedulerContextProtocol>) -> Bool {
        // swiftlint:disable force_cast
        let context = context.pointee
            as! SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        // swiftlint:enable force_cast
        return context.data.isFinished
    }

    public func isSuspended(context: UnsafePointer<SchedulerContextProtocol>) -> Bool {
        // swiftlint:disable force_cast
        let context = context.pointee
            as! SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        // swiftlint:enable force_cast
        return context.data.isSuspended
    }

    public func next(context contextPtr: UnsafeMutablePointer<SchedulerContextProtocol>) {
        // swiftlint:disable force_cast
        var context = contextPtr.pointee
            as! SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        // swiftlint:enable force_cast
        if verbose > 1 || (verbose == 1 && context.data.currentState != context.data.previousState) {
            print("\(context.fsmName).", terminator: "")
        }
        context.states = states
        context.fsmContext.duration = context.duration
        defer {
            context.states = nil
            context.fsmContext.duration = nil
        }
        let nextStateRaw = ringlet.execute(context: context)
        let nextState = nextStateRaw ?? context.currentState
        context.transitioned = nextStateRaw != nil
        context.data.previousState = context.currentState
        context.data.currentState = nextState
        if context.data.fsmContext.status == .suspending {
            context.data.suspend()
        } else if context.data.fsmContext.status == .resuming {
            context.data.resume()
        } else if context.data.fsmContext.status == .restarting {
            context.data.restart()
        } else {
            context.data.fsmContext.status = .executing(transitioned: nextStateRaw != nil)
        }
        contextPtr.pointee = context as SchedulerContextProtocol
    }

    public func saveSnapshot(context contextPtr: UnsafeMutablePointer<SchedulerContextProtocol>) {
        // swiftlint:disable force_cast
        var context = contextPtr.pointee
            as! SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        // swiftlint:enable force_cast
        let state = self.states[context.data.previousState]
        let actuatorValues = context.data.actuatorValues
        withUnsafePointer(to: &context.environment) { environment in
            state.saveSnapshot(environment, handlers, actuatorValues)
        }
        contextPtr.pointee = context as SchedulerContextProtocol
    }

    public func takeSnapshot(context contextPtr: UnsafeMutablePointer<SchedulerContextProtocol>) {
        // swiftlint:disable force_cast
        var context = contextPtr.pointee
            as! SchedulerContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>
        // swiftlint:enable force_cast
        var environment = Environment()
        let state = self.states[context.data.currentState]
        let actuatorValues = context.data.actuatorValues
        withUnsafeMutablePointer(to: &environment) { environment in
            state.takeSnapshot(environment, handlers, UnsafePointer(actuatorValues))
        }
        context.environment = environment
        contextPtr.pointee = context as SchedulerContextProtocol
    }

}
