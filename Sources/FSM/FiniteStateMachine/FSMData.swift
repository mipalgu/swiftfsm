public struct FSMData<
    RingletsContext: DataStructure,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: FiniteStateMachineOperations {

    public var acceptingStates: [Bool]

    public var stateContexts: [AnyStateContext<Context, Environment, Parameters, Result>]

    public var fsmContext: FSMContext<Context, Environment, Parameters, Result>

    public var ringletContext: RingletsContext

    public var actuatorValues: [Sendable]

    public var initialState: StateID

    public var currentState: StateID

    public var previousState: StateID

    public var suspendState: StateID

    public var suspendedState: StateID?

    public var cloned: Self {
        let newFsmContext = fsmContext.cloned
        return Self(
            acceptingStates: acceptingStates,
            stateContexts: stateContexts.map { $0.clone(fsmContext: newFsmContext) },
            fsmContext: newFsmContext,
            ringletContext: ringletContext,
            actuatorValues: actuatorValues,
            initialState: initialState,
            currentState: currentState,
            previousState: previousState,
            suspendState: suspendState,
            suspendedState: suspendedState
        )
    }

    public var isFinished: Bool {
        currentState == previousState
            && currentState != suspendState
            && acceptingStates[currentState]
    }

    public var isSuspended: Bool {
        currentState == suspendState
    }

    public init(
        acceptingStates: [Bool],
        stateContexts: [AnyStateContext<Context, Environment, Parameters, Result>],
        fsmContext: FSMContext<Context, Environment, Parameters, Result>,
        ringletContext: RingletsContext,
        actuatorValues: [Sendable],
        initialState: Int,
        currentState: Int,
        previousState: Int,
        suspendState: Int,
        suspendedState: Int?
    ) {
        self.acceptingStates = acceptingStates
        self.stateContexts = stateContexts
        self.fsmContext = fsmContext
        self.ringletContext = ringletContext
        self.actuatorValues = actuatorValues
        self.initialState = initialState
        self.currentState = currentState
        self.previousState = previousState
        self.suspendState = suspendState
        self.suspendedState = suspendedState
    }

    public mutating func restart() {
        currentState = initialState
        fsmContext.status = .restarted(transitioned: currentState != previousState)
    }

    public mutating func resume() {
        guard let currentSuspendedState = suspendedState else {
            return
        }
        currentState = currentSuspendedState
        suspendedState = nil
        fsmContext.status = .resumed(transitioned: currentState != previousState)
    }

    public mutating func suspend() {
        guard suspendedState == nil else {
            return
        }
        suspendedState = currentState
        currentState = suspendState
        fsmContext.status = .suspended(transitioned: currentState != previousState)
    }

}
