public struct FSMState<
    StateType: TypeErasedState,
    Parameters: DataStructure,
    Result: DataStructure,
    Context: ContextProtocol,
    Environment: EnvironmentSnapshot
> {

    public let information: StateInformation

    public var id: StateID {
        information.id
    }

    public var name: String {
        information.name
    }

    public let stateType: StateType

    public let transitions:
        [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>]

    // swiftlint:disable line_length

    public let takeSnapshot: @Sendable (UnsafeMutablePointer<Environment>, Handlers, UnsafePointer<Sendable>) -> Void

    public let saveSnapshot: @Sendable (UnsafePointer<Environment>, Handlers, UnsafeMutablePointer<Sendable>) -> Void

    public init(
        id: StateID,
        name: String,
        stateType: StateType,
        transitions: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>],
        takeSnapshot: @Sendable @escaping (UnsafeMutablePointer<Environment>, Handlers, UnsafePointer<Sendable>) -> Void,
        saveSnapshot: @Sendable @escaping (UnsafePointer<Environment>, Handlers, UnsafeMutablePointer<Sendable>) -> Void
    ) {
        self.init(
            information: StateInformation(id: id, name: name),
            stateType: stateType,
            transitions: transitions,
            takeSnapshot: takeSnapshot,
            saveSnapshot: saveSnapshot
        )
    }

    public init(
        information: StateInformation,
        stateType: StateType,
        transitions: [AnyTransition<AnyStateContext<Context, Environment, Parameters, Result>, StateID>],
        takeSnapshot: @Sendable @escaping (UnsafeMutablePointer<Environment>, Handlers, UnsafePointer<Sendable>) -> Void,
        saveSnapshot: @Sendable @escaping (UnsafePointer<Environment>, Handlers, UnsafeMutablePointer<Sendable>) -> Void
    ) {
        self.information = information
        self.stateType = stateType
        self.transitions = transitions
        self.takeSnapshot = takeSnapshot
        self.saveSnapshot = saveSnapshot
    }

    // swiftlint:enable line_length

}
