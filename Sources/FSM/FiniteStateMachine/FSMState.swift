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

    // swiftlint:disable line_length

    public let takeSnapshot: @Sendable (UnsafeMutablePointer<Environment>, FSMHandlers<Environment>, UnsafePointer<Sendable>) -> Void

    public let saveSnapshot: @Sendable (UnsafePointer<Environment>, FSMHandlers<Environment>, UnsafeMutablePointer<Sendable>) -> Void

    public init(
        id: StateID,
        name: String,
        stateType: StateType,
        transitions: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>],
        takeSnapshot: @Sendable @escaping (UnsafeMutablePointer<Environment>, FSMHandlers<Environment>, UnsafePointer<Sendable>) -> Void,
        saveSnapshot: @Sendable @escaping (UnsafePointer<Environment>, FSMHandlers<Environment>, UnsafeMutablePointer<Sendable>) -> Void
    ) {
        self.id = id
        self.name = name
        self.stateType = stateType
        self.transitions = transitions
        self.takeSnapshot = takeSnapshot
        self.saveSnapshot = saveSnapshot
    }

    // swiftlint:enable line_length

}
