public struct FSMData<
    RingletsContext: DataStructure,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: FiniteStateMachineOperations {

    public typealias Handlers = FSMHandlers<Environment>

    public var acceptingStates: UnsafeMutablePointer<Bool>

    public var stateContexts: UnsafePointer<AnyStateContext<Context, Environment, Parameters, Result>>

    public var fsmContext: FSMContext<Context, Environment, Parameters, Result>

    public var ringletContext: RingletsContext

    public var actuatorValues: UnsafeMutablePointer<Sendable>

    public var initialState: StateID

    public var currentState: StateID

    public var previousState: StateID

    public var suspendState: StateID

    public var suspendedState: StateID?

    public var isFinished: Bool {
        currentState == previousState
            && currentState != suspendState
            && acceptingStates[currentState]
    }

    public var isSuspended: Bool {
        currentState == suspendState
    }

    init(
        acceptingStates: UnsafeMutablePointer<Bool>,
        stateContexts: UnsafePointer<AnyStateContext<Context, Environment, Parameters, Result>>,
        fsmContext: FSMContext<Context, Environment, Parameters, Result>,
        ringletContext: RingletsContext,
        actuatorValues: UnsafeMutablePointer<Sendable>,
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
