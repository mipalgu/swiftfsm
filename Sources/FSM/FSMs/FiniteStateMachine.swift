public struct FiniteStateMachine<
    StateType: TypeErasedState,
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> where StateType.FSMsContext == Context,
    StateType.Environment == Environment,
    Ringlet.StateType == StateType,
    Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID> {

    public struct Handlers {

        public var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>]

        public var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>]

        public var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]

    }

    public struct State {

        public let id: StateID

        public let name: String

        public let environmentVariables: Set<PartialKeyPath<Environment>>

        public let stateType: StateType

        public let transitions: [AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID>]

    }

    public struct Data: Sendable, FiniteStateMachineOperations {

        public var acceptingStates: [Bool]

        public var stateContexts: [Sendable]

        public var fsmContext: FSMContext<Context, Environment, Parameters, Result>

        public var ringletContext: Ringlet.Context

        public var actuatorValues: [PartialKeyPath<Environment>: Sendable]

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

        fileprivate init(
            acceptingStates: [Bool],
            stateContexts: [Sendable],
            fsmContext: FSMContext<Context, Environment, Parameters, Result>,
            ringletContext: Ringlet.Context,
            actuatorValues: [PartialKeyPath<Environment>: Sendable],
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

        public mutating func saveSnapshot(
            environmentVariables: Set<PartialKeyPath<Environment>>,
            handlers: Handlers
        ) {
            for keyPath in environmentVariables {
                if let handler = handlers.actuators[keyPath] {
                    handler.saveSnapshot(value: fsmContext.environment[keyPath: keyPath])
                    actuatorValues[keyPath] = fsmContext.environment[keyPath: keyPath]
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
                } else if let handler = handlers.actuators[keyPath], let value = actuatorValues[keyPath] {
                    handler.update(environment: &environment, with: value)
                }
            }
            fsmContext.environment = environment
        }

    }

    private let _initialData: () -> Data

    public var initialData: Data {
        _initialData()
    }

    public let states: [State]

    public let ringlet: Ringlet

    public let handlers: Handlers

    public init<Model: FSMModel>(
        model: Model,
        parameters: Parameters
    ) where Model.StateType == StateType,
            Model.Ringlet == Ringlet,
            Model.Parameters == Parameters,
            Model.Result == Result,
            Model.Context == Context,
            Model.Environment == Environment {
        var newIds: [StateID: Int] = [:]
        var latestID = 0
        func id(for state: StateID) -> Int {
            if let id = newIds[state] {
                return id
            }
            let id = latestID
            latestID += 1
            newIds[state] = id
            return id
        }
        let anyStates = model.anyStates
        let stateTypes = model.states
        let contexts = model.stateContexts
        let transitions = model.transitions
        var states = anyStates.map {
            let oldID = $1.information.id
            let newID = id(for: $1.information.id)
            let name = $1.information.name
            guard
                let environmentVariables = $1.erasedEnvironmentVariables
                    as? [PartialKeyPath<Environment>]
            else {
                fatalError("Unable to cast environment variables for state \(name).")
            }
            guard let stateType = stateTypes[oldID] else {
                fatalError("Unable to fetch state type for state \(name).")
            }
            guard let transitions = transitions[oldID] else {
                fatalError("Unable to fetch transitions for state \(name).")
            }
            let newTransitions = transitions.map {
                $0.map { id(for: $0) }
            }
            return State(
                id: newID,
                name: name,
                environmentVariables: Set(environmentVariables),
                stateType: stateType,
                transitions: newTransitions
            )
        }
        var newContexts = anyStates.map {
            let oldID = $1.information.id
            guard let context = contexts[oldID] else {
                fatalError("Unable to fetch context for state \($1.information.name).")
            }
            return context
        }
        func newState(named name: String, transitions: [Int] = []) -> Int {
            let oldID = IDRegistrar.id(of: name)
            guard anyStates[oldID] == nil else {
                fatalError("The \(name) state name is reserved. Please rename your state.")
            }
            let newID = id(for: oldID)
            guard newID == states.count, newID == newContexts.count else {
                fatalError("Calculated invalid id (\(newID)) for new state.")
            }
            let (context, stateType) = StateType.empty
            states.append(State(
                id: newID,
                name: name,
                environmentVariables: [],
                stateType: stateType,
                transitions: transitions.map { AnyTransition(to: $0) }
            ))
            newContexts.append(context)
            return newID
        }
        let modelInitialState = id(for: model[keyPath: model.initialState].id)
        let actualInitialState = newState(named: "__Initial", transitions: [modelInitialState])
        let initialState = actualInitialState
        let currentState = actualInitialState
        let previousState = newState(named: "__Previous")
        let suspendState: Int
        if let suspendStatePath = model.suspendState {
            suspendState = id(for: model[keyPath: suspendStatePath].id)
        } else {
            suspendState = newState(named: "__Suspend")
        }
        let acceptingStates = states.map { $0.transitions.isEmpty }
        let fsmContext = model.initialContext(parameters: parameters)
        let handlers = Handlers(
            actuators: model.actuators,
            externalVariables: model.externalVariables,
            sensors: model.sensors
        )
        self.init(
            states: states,
            ringlet: model.initialRinglet,
            handlers: handlers,
            initialData: {
                Data(
                    acceptingStates: acceptingStates,
                    stateContexts: newContexts,
                    fsmContext: fsmContext,
                    ringletContext: Ringlet.Context(),
                    actuatorValues: model.actuatorInitialValues,
                    initialState: initialState,
                    currentState: currentState,
                    previousState: previousState,
                    suspendState: suspendState,
                    suspendedState: nil
                )
            }
        )
    }

    private init(states: [State], ringlet: Ringlet, handlers: Handlers, initialData: @escaping () -> Data) {
        self.states = states
        self.ringlet = ringlet
        self.handlers = handlers
        self._initialData = initialData
    }

    public mutating func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: inout Data) {
        let state = states[data.currentState]
        data.fsmContext.state = data.stateContexts[data.currentState]
        let nextState = ringlet.execute(
            id: data.currentState,
            state: state.stateType,
            transitions: state.transitions,
            fsmContext: &data.fsmContext,
            context: &data.ringletContext
        )
        data.previousState = data.currentState
        data.currentState = nextState
        if data.fsmContext.status == .suspending {
            data.suspend()
        } else if data.fsmContext.status == .resuming {
            data.resume()
        } else if data.fsmContext.status == .restarting {
            data.restart()
        } else {
            data.fsmContext.status = .executing(transitioned: data.currentState != data.previousState)
        }
    }

    public mutating func saveSnapshot(forState stateID: StateID? = nil, data: inout Data) {
        data.saveSnapshot(
            environmentVariables: states[stateID ?? data.currentState].environmentVariables,
            handlers: handlers
        )
    }

    public mutating func takeSnapshot(forState stateID: StateID? = nil, data: inout Data) {
        data.takeSnapshot(
            environmentVariables: states[stateID ?? data.currentState].environmentVariables,
            handlers: handlers
        )
    }

}
