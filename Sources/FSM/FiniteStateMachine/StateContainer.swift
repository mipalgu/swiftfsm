public final class StateContainer<
    StateType: TypeErasedState,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> {

    public let states: [FSMState<StateType, Parameters, Result, Context, Environment>]

    internal init(states: [FSMState<StateType, Parameters, Result, Context, Environment>]) {
        self.states = states
    }

}
