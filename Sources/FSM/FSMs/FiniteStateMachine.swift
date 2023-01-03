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
    Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment>, StateID> {

    struct State {

        let id: StateID

        let name: String

        let context: Sendable

        let environmentVariables: Set<PartialKeyPath<Environment>>

        let stateType: StateType

        let transitions: [AnyTransition<FSMContext<Context, Environment>, StateID>]

    }

    public struct Data: Sendable {

        var states: [Int: State]

        var fsmContext: FSMContext<Context, Environment>

        var ringletContext: Ringlet.Context

        var initialState: StateID

        var currentState: StateID

        var previousState: StateID

        var suspendState: StateID

        var suspendedState: StateID?

        fileprivate init<Model: FSMModel>(
            model: Model
        ) where Model.StateType == StateType,
            Model.Ringlet == Ringlet,
            Model.Parameters == Parameters,
            Model.Result == Result,
            Model.Context == Context,
            Model.Environment == Environment {
            let anyStates = model.anyStates
            let stateTypes = model.states
            let contexts = model.stateContexts
            let transitions = model.transitions
            var states = anyStates.mapValues {
                let id = $0.information.id
                let name = $0.information.name
                guard let context = contexts[id] else {
                    fatalError("Unable to fetch context for state \(name).")
                }
                guard
                    let environmentVariables = $0.erasedEnvironmentVariables
                        as? [PartialKeyPath<Environment>]
                else {
                    fatalError("Unable to cast environment variables for state \(name).")
                }
                guard let stateType = stateTypes[id] else {
                    fatalError("Unable to fetch state type for state \(name).")
                }
                guard let transitions = transitions[id] else {
                    fatalError("Unable to fetch transitions for state \(name).")
                }
                return State(
                    id: id,
                    name: name,
                    context: context,
                    environmentVariables: Set(environmentVariables),
                    stateType: stateType,
                    transitions: transitions
                )
            }
            func newState(named name: String, transitions: [StateID] = []) -> StateID {
                let id = IDRegistrar.id(of: name)
                guard states[id] == nil else {
                    fatalError("The \(name) state name is reserved. Please rename your state.")
                }
                let (context, stateType) = StateType.empty
                states[id] = State(
                    id: id,
                    name: name,
                    context: context,
                    environmentVariables: [],
                    stateType: stateType,
                    transitions: transitions.map { AnyTransition(to: $0) }
                )
                return id
            }
            self.fsmContext = model.initialContext
            self.ringletContext = Ringlet.Context()
            let modelInitialState = model[keyPath: model.initialState].id
            let actualInitialState = newState(named: "__Initial", transitions: [modelInitialState])
            self.initialState = actualInitialState
            self.currentState = actualInitialState
            self.previousState = newState(named: "__Previous")
            if let suspendStatePath = model.suspendState {
                self.suspendState = model[keyPath: suspendStatePath].id
            } else {
                self.suspendState = newState(named: "__Suspend")
            }
            self.states = states
        }

        mutating func update(fromEnvironment environment: Environment) {
            fsmContext.environment.update(data: environment)
        }

    }

    public private(set) var data: Data

    public private(set) var ringlet: Ringlet

    public var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>]

    public var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>]

    public var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]

    public init<Model: FSMModel>(
        model: Model
    ) where Model.StateType == StateType,
            Model.Ringlet == Ringlet,
            Model.Parameters == Parameters,
            Model.Result == Result,
            Model.Context == Context,
            Model.Environment == Environment {
        self.init(
            data: Data(model: model),
            ringlet: model.initialRinglet,
            actuators: model.actuators,
            externalVariables: model.externalVariables,
            sensors: model.sensors
        )
    }

    private init(
        data: Data,
        ringlet: Ringlet,
        actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>],
        externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>],
        sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]
    ) {
        self.data = data
        self.ringlet = ringlet
        self.actuators = actuators
        self.externalVariables = externalVariables
        self.sensors = sensors
    }

    mutating func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler) {
        let state = data.states[data.currentState]!
        data.fsmContext.state = state.context
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
            data.suspendedState = data.currentState
            data.currentState = data.suspendState
            data.fsmContext.status = .suspended(transitioned: data.currentState != data.previousState)
        } else if data.fsmContext.status == .resuming, let suspendedState = data.suspendedState {
            data.currentState = suspendedState
            data.suspendedState = nil
            data.fsmContext.status = .resumed(transitioned: data.currentState != data.previousState)
        } else if data.fsmContext.status == .restarting {
            data.currentState = data.initialState
            data.fsmContext.status = .restarted(transitioned: data.currentState != data.previousState)
        } else {
            data.fsmContext.status = .executing(transitioned: data.currentState != data.previousState)
        }
    }

    mutating func saveSnapshot(forState stateID: StateID? = nil) {
        let state = data.states[stateID ?? data.currentState]!
        for keyPath in state.environmentVariables {
            if var handler = actuators[keyPath] {
                handler.update(from: data.fsmContext.environment.data)
                handler.saveSnapshot()
                actuators[keyPath] = handler
            }
            if var handler = externalVariables[keyPath] {
                handler.update(from: data.fsmContext.environment.data)
                handler.saveSnapshot()
                externalVariables[keyPath] = handler
            }
        }
    }

    mutating func takeSnapshot(forState stateID: StateID? = nil) {
        let state = data.states[stateID ?? data.currentState]!
        var environment = Environment()
        for keyPath in state.environmentVariables {
            if var handler = sensors[keyPath] {
                handler.takeSnapshot()
                handler.update(environment: &environment)
                sensors[keyPath] = handler
            }
            if let handler = actuators[keyPath] {
                handler.update(environment: &environment)
                actuators[keyPath] = handler
            }
            if var handler = externalVariables[keyPath] {
                handler.takeSnapshot()
                handler.update(environment: &environment)
                externalVariables[keyPath] = handler
            }
        }
        data.fsmContext.environment = Snapshot(data: environment, whitelist: state.environmentVariables)
    }

}
