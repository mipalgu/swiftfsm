import FSM

/// A data structure that classifies `Executable`s by their function in a
/// schedule.
enum ExecutableType {

    /// An executable that can execute without being called by another
    /// executalbe.
    case controllable(any Executable)

    // case parameterised(any Executable)

    /// Returns the underlying executable.
    var executable: any Executable {
        switch self {
        case .controllable(let executable):
            return executable
        }
    }

}
