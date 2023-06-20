import FSM

public struct EmptyLLFSMState<
    FSMsContext: ContextProtocol,
    Environment: EnvironmentSnapshot,
    Parameters: DataStructure,
    Result: DataStructure
>: LLFSMState, Hashable, Codable, Sendable {

    public typealias Context = EmptyDataStructure
    public typealias Environment = Environment
    public typealias FSMsContext = FSMsContext
    public typealias Parameters = Parameters
    public typealias Result = Result

    public init() {}

}
