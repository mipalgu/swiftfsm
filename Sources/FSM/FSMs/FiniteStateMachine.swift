public struct FiniteStateMachine<
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

    public struct Data: FSMData {

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

        fileprivate init(
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

    public let states: [State]

    public let ringlet: Ringlet

    public let handlers: Handlers

    public static func initial<Model: FSMModel>(
        from model: Model,
        with parameters: Parameters
    ) -> (Self, Self.Data) where Model.StateType == StateType,
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
        var actuatorsArr = Array(model.actuators)
        var externalVariablesArr = Array(model.externalVariables)
        var sensorsArr = Array(model.sensors)
        for index in actuatorsArr.indices {
            actuatorsArr[index].value.index = index
        }
        for index in externalVariablesArr.indices {
            externalVariablesArr[index].value.index = index
        }
        for index in sensorsArr.indices {
            sensorsArr[index].value.index = index
        }
        let actuators = Dictionary(uniqueKeysWithValues: actuatorsArr)
        let externalVariables = Dictionary(uniqueKeysWithValues: externalVariablesArr)
        let sensors = Dictionary(uniqueKeysWithValues: sensorsArr)
        let handlers = Handlers(
            actuators: actuators,
            externalVariables: externalVariables,
            sensors: sensors
        )
        let actuatorValues: [Sendable] = model.actuatorInitialValues.map {
            guard let handler = actuators[$0] else {
                fatalError("Unable to fetch handler from keypath.")
            }
            return (handler.index, $1)
        }.sorted {
            $0.0 < $1.0
        }.map {
            $1 as Sendable
        }
        guard actuatorValues.count == actuators.count else {
            fatalError("Unable to set up actuatorValues for actuators.")
        }
        let fsmID = IDRegistrar.id(of: model.name)
        let fsm = FiniteStateMachine(states: states, ringlet: model.initialRinglet, handlers: handlers)
        let data = Data(
            fsm: fsmID,
            acceptingStates: acceptingStates,
            stateContexts: newContexts,
            fsmContext: fsmContext,
            ringletContext: Ringlet.Context(),
            actuatorValues: actuatorValues,
            initialState: initialState,
            currentState: currentState,
            previousState: previousState,
            suspendState: suspendState,
            suspendedState: nil
        )
        return (fsm, data)
    }

    private init(states: [State], ringlet: Ringlet, handlers: Handlers) {
        self.states = states
        self.ringlet = ringlet
        self.handlers = handlers
    }

    public func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: inout Sendable) {
        var temp = unsafeBitCast(data, to: Data.self)
        let state = states[temp.currentState]
        temp.fsmContext.state = temp.stateContexts[temp.currentState]
        let nextState = ringlet.execute(
            id: temp.currentState,
            state: state.stateType,
            transitions: state.transitions,
            fsmContext: &temp.fsmContext,
            context: &temp.ringletContext
        )
        temp.previousState = temp.currentState
        temp.currentState = nextState
        if temp.fsmContext.status == .suspending {
            temp.suspend()
        } else if temp.fsmContext.status == .resuming {
            temp.resume()
        } else if temp.fsmContext.status == .restarting {
            temp.restart()
        } else {
            temp.fsmContext.status = .executing(transitioned: temp.currentState != temp.previousState)
        }
        data = temp as Sendable
    }

    public func saveSnapshot(data: inout Sendable) {
        var temp = unsafeBitCast(data, to: Data.self)
        temp.saveSnapshot(
            environmentVariables: states[temp.currentState].environmentVariables,
            handlers: handlers
        )
        data = temp as Sendable
    }

    public func takeSnapshot(data: inout Sendable) {
        var temp = unsafeBitCast(data, to: Data.self)
        temp.takeSnapshot(
            environmentVariables: states[temp.currentState].environmentVariables,
            handlers: handlers
        )
        data = temp as Sendable
    }

}
