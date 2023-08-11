public struct FSMState<
    StateType: TypeErasedState,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> {

    public let id: StateID

    public let name: String

    public let stateType: StateType

    public let transitions:
        [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]

    public let takeSnapshot: @Sendable (UnsafePointer<Environment>, FSMHandlers<Environment>) -> Void

    public let saveSnapshot: @Sendable (UnsafePointer<Environment>, FSMHandlers<Environment>) -> Void

    public init(
        id: StateID,
        name: String,
        stateType: StateType,
        transitions: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>],
        takeSnapshot: @Sendable @escaping (UnsafePointer<Environment>, FSMHandlers<Environment>) -> Void,
        saveSnapshot: @Sendable @escaping (UnsafePointer<Environment>, FSMHandlers<Environment>) -> Void
    ) {
        self.id = id
        self.name = name
        self.stateType = stateType
        self.transitions = transitions
        self.takeSnapshot = takeSnapshot
        self.saveSnapshot = saveSnapshot
    }

}
