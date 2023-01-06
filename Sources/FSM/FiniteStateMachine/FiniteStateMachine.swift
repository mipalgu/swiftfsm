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

    public typealias StateType = StateType
    public typealias RingletsContext = Ringlet.Context
    public typealias FSMContext = Context
    public typealias Environment = Environment
    public typealias Parameters = Parameters
    public typealias Result = Result

    public typealias Data = FSMData<Ringlet.Context, Parameters, Result, Context, Environment>

    public typealias Handlers = FSMHandlers<Environment>

    public typealias State = FSMState<StateType, Parameters, Result, Context, Environment>

    public typealias States = StateContainer<StateType, Parameters, Result, Context, Environment>

    public let stateContainer: States

    public let ringlet: Ringlet

    public let handlers: Handlers

    public var states: [State] {
        stateContainer.states
    }

    public static func initial<Model: FSMModel>(
        from model: Model,
        with parameters: Parameters
    ) -> (
        FiniteStateMachine<
            Model.StateType,
            Model.Ringlet,
            Model.Parameters,
            Model.Result,
            Model.Context,
            Model.Environment
        >,
        FSMData<
            Model.Ringlet.Context,
            Model.Parameters,
            Model.Result,
            Model.Context,
            Model.Environment
        >
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
        let fsm = FiniteStateMachine(
            stateContainer: States(states: states),
            ringlet: model.initialRinglet,
            handlers: handlers
        )
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

    private init(stateContainer: States, ringlet: Ringlet, handlers: Handlers) {
        self.stateContainer = stateContainer
        self.ringlet = ringlet
        self.handlers = handlers
    }

    public func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: AnyObject) {
        let context = unsafeDowncast(
            data,
            to: RingletContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.stateContainer = stateContainer
        defer { context.stateContainer = nil }
        let state = states[context.currentState]
        context.data.fsmContext.state = context.data.stateContexts[context.currentState]
        let nextState = ringlet.execute(
            id: context.currentState,
            state: state.stateType,
            transitions: state.transitions,
            context: context
        )
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

    public func saveSnapshot(data: AnyObject) {
        let context = unsafeDowncast(
            data,
            to: RingletContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.data.saveSnapshot(
            environmentVariables: states[context.data.currentState].environmentVariables,
            handlers: handlers
        )
    }

    public func takeSnapshot(data: AnyObject) {
        let context = unsafeDowncast(
            data,
            to: RingletContext<StateType, Ringlet.Context, Context, Environment, Parameters, Result>.self
        )
        context.data.takeSnapshot(
            environmentVariables: states[context.data.currentState].environmentVariables,
            handlers: handlers
        )
    }

}
