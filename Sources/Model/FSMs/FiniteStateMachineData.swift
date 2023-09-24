import FSM

public struct FiniteStateMachineData<
    StateType: TypeErasedState,
    Context: ContextProtocol,
    Environment: EnvironmentProtocol,
    Parameters: DataStructure,
    Result: DataStructure
> where StateType.FSMsContext == Context, StateType.Environment == Environment {

    public typealias FactoryFunction = ((any DataStructure)?, UnsafeMutablePointer<SchedulerContextProtocol>, UnsafeMutablePointer<Bool>, UnsafeMutablePointer<AnyStateContext<Context, Environment, Parameters, Result>>, UnsafeMutablePointer<Sendable>) -> Void

    public var acceptingStates: UnsafeMutablePointer<Bool>

    public var states: UnsafeMutablePointer<FSMState<StateType, Parameters, Result, Context, Environment>>

    public var stateContexts: UnsafeMutablePointer<AnyStateContext<Context, Environment, Parameters, Result>>

    public var actuatorValues: UnsafeMutablePointer<Sendable>

    public var executable: Executable

    public var factory: FactoryFunction

    public func initialiseContext(
        parameters: (any DataStructure)?,
        context: UnsafeMutablePointer<SchedulerContextProtocol>
    ) {
        factory(parameters, context, acceptingStates, stateContexts, actuatorValues)
    }

    public func deallocate<Model: FSM>(model: Model)
        where Model.StateType == StateType,
        Model.Context == Context,
        Model.Environment == Environment,
        Model.Parameters == Parameters,
        Model.Result == Result {
        model.deallocateAcceptingStatesMemory(acceptingStates)
        model.deallocateStatesMemory(states)
        model.deallocateStateContextsMemory(stateContexts)
        model.deallocateActuatorValuesMemory(actuatorValues)
    }

}

public struct ErasedFiniteStateMachineData {

    public typealias FactoryFunction = ((any DataStructure)?, UnsafeMutablePointer<SchedulerContextProtocol>, UnsafeMutablePointer<Bool>, UnsafeMutableRawPointer, UnsafeMutablePointer<Sendable>) -> Void

    public var acceptingStates: UnsafeMutablePointer<Bool>

    public var states: UnsafeMutableRawPointer

    public var stateContexts: UnsafeMutableRawPointer

    public var actuatorValues: UnsafeMutablePointer<Sendable>

    public var executable: Executable

    public var factory: FactoryFunction

    public init<
        StateType: TypeErasedState,
        Context: ContextProtocol,
        Environment: EnvironmentProtocol,
        Parameters: DataStructure,
        Result: DataStructure
    >(_ other: FiniteStateMachineData<StateType, Context, Environment, Parameters, Result>) where
        StateType.FSMsContext == Context,
        StateType.Environment == Environment {
        self.acceptingStates = other.acceptingStates
        self.states = UnsafeMutableRawPointer(other.states)
        self.stateContexts = UnsafeMutableRawPointer(other.stateContexts)
        self.actuatorValues = other.actuatorValues
        self.executable = other.executable
        self.factory = {
            other.factory(
                $0,
                $1,
                $2,
                $3.assumingMemoryBound(
                    to: AnyStateContext<Context, Environment, Parameters, Result>.self
                ),
                $4
            )
        }
    }

    public func initialiseContext(
        parameters: (any DataStructure)?,
        context: UnsafeMutablePointer<SchedulerContextProtocol>
    ) {
        factory(parameters, context, acceptingStates, stateContexts, actuatorValues)
    }

    public func deallocate<Model: FSM>(model: Model) {
        model.deallocateAcceptingStatesMemory(acceptingStates)
        model.deallocateStatesMemory(
            states.assumingMemoryBound(
                to: FSMState<Model.StateType, Model.Parameters, Model.Result, Model.Context, Model.Environment>.self
            )
        )
        model.deallocateStateContextsMemory(
            stateContexts.assumingMemoryBound(
                to: AnyStateContext<Model.Context, Model.Environment, Model.Parameters, Model.Result>.self
            )
        )
        model.deallocateActuatorValuesMemory(actuatorValues)
    }

}
