public struct FSMState<
    StateType: TypeErasedState,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> {

    public let id: StateID

    public let name: String

    public let environmentVariables: Set<PartialKeyPath<Environment>>

    public let stateType: StateType

    public let transitions:
        [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]

    public init(
        id: StateID,
        name: String,
        environmentVariables: Set<PartialKeyPath<Environment>>,
        stateType: StateType,
        transitions: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]
    ) {
        self.id = id
        self.name = name
        self.environmentVariables = environmentVariables
        self.stateType = stateType
        self.transitions = transitions
    }

}
