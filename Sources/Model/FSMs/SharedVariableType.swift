/// Characterises the different types of shared variables available to FSM's.
public enum SharedVariableType: Hashable, Codable, Sendable {

    /// A write-only variable to the environment.
    case actuator

    /// A variable that reads from and writes to the environment.
    case externalVariable

    /// A shared variable amongst FSM's.
    case globalVariable

    /// A read-only variable to the environment.
    case sensor

}
