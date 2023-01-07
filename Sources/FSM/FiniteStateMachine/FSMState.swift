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

    public let transitions: [
        AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>
    ]

}
