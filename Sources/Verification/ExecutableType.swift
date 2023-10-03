import FSM

/// A data structure that classifies `Executable`s by their function in a
/// schedule.
public enum ExecutableType {

    /// An executable that can execute without being called by another
    /// executable.
    case controllable(any Executable)

    /// An executable that must be called first before executing.
    case parameterised(any Executable)

    /// Indicates whether this executable is parameterised.
    var isParameterised: Bool {
        switch self {
        case .parameterised:
            return true
        default:
            return false
        }
    }

    /// Returns the underlying executable.
    var executable: any Executable {
        switch self {
        case .controllable(let executable), .parameterised(let executable):
            return executable
        }
    }

}
