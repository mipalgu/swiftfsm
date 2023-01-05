public struct FSMData<
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: FSMDataProtocol {

    public typealias Handlers = FSMHandlers<Environment>

    public var fsm: Int

    public var acceptingStates: [Bool]

    public var stateContexts: [Sendable]

    public var fsmContext: FSMContext<Context, Environment, Parameters, Result>

    public var ringletContext: Ringlet.Context

    public var actuatorValues: [Sendable]

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
        fsm: Int,
        acceptingStates: [Bool],
        stateContexts: [Sendable],
        fsmContext: FSMContext<Context, Environment, Parameters, Result>,
        ringletContext: Ringlet.Context,
        actuatorValues: [Sendable],
        initialState: Int,
        currentState: Int,
        previousState: Int,
        suspendState: Int,
        suspendedState: Int?
    ) {
        self.fsm = fsm
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

    public mutating func saveSnapshot(
        environmentVariables: Set<PartialKeyPath<Environment>>,
        handlers: Handlers
    ) {
        for keyPath in environmentVariables {
            if let handler = handlers.actuators[keyPath] {
                handler.saveSnapshot(value: fsmContext.environment[keyPath: keyPath])
                actuatorValues[handler.index] = fsmContext.environment[keyPath: keyPath]
            } else if let handler = handlers.externalVariables[keyPath] {
                handler.saveSnapshot(value: fsmContext.environment[keyPath: keyPath])
            }
        }
    }

    public mutating func takeSnapshot(
        environmentVariables: Set<PartialKeyPath<Environment>>,
        handlers: Handlers
    ) {
        var environment = Environment()
        for keyPath in environmentVariables {
            if let handler = handlers.sensors[keyPath] {
                handler.update(environment: &environment, with: handler.takeSnapshot())
            } else if let handler = handlers.externalVariables[keyPath] {
                handler.update(environment: &environment, with: handler.takeSnapshot())
            } else if let handler = handlers.actuators[keyPath] {
                handler.update(environment: &environment, with: actuatorValues[handler.index])
            }
        }
        fsmContext.environment = environment
    }

}
