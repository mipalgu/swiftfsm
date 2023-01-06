public final class FiniteStateMachine<
    StateType: TypeErasedState,
    Ringlet: RingletProtocol,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
>: Executable, StateContainerProtocol where StateType.FSMsContext == Context,
    StateType.Environment == Environment,
    Ringlet.StateType == StateType,
    Ringlet.TransitionType == AnyTransition<FSMContext<Context, Environment, Parameters, Result>, StateID> {

    public typealias StateType = StateType
    public typealias RingletsContext = Ringlet.Context
    public typealias FSMContext = Context
    public typealias Environment = Environment
    public typealias Parameters = Parameters
    public typealias Result = Result

    public typealias Data = FSMData<Ringlet, Parameters, Result, Context, Environment>

    public typealias Handlers = FSMHandlers<Environment>

    public typealias State = FSMState<StateType, Parameters, Result, Context, Environment>

    public let states: [State]

    public let ringlet: Ringlet

    public let handlers: Handlers

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
            Model.Ringlet,
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
        let fsm = FiniteStateMachine(states: states, ringlet: model.initialRinglet, handlers: handlers)
        let ringletContext = RingletContext(ringlet: Ringlet.Context(), fsmContext: fsmContext)
        let data = Data(
            fsm: fsmID,
            acceptingStates: acceptingStates,
            stateContexts: newContexts,
            ringletContext: ringletContext,
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
        temp.ringletContext.fsmContext.state = temp.stateContexts[temp.currentState]
        let nextState = ringlet.execute(
            id: temp.currentState,
            state: state.stateType,
            transitions: state.transitions,
            context: temp.ringletContext
        )
        temp.previousState = temp.currentState
        temp.currentState = nextState
        if temp.ringletContext.fsmContext.status == .suspending {
            temp.suspend()
        } else if temp.ringletContext.fsmContext.status == .resuming {
            temp.resume()
        } else if temp.ringletContext.fsmContext.status == .restarting {
            temp.restart()
        } else {
            temp.ringletContext.fsmContext.status = .executing(
                transitioned: temp.currentState != temp.previousState
            )
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

    public func state(at id: Int) -> State {
        states[id]
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
