/// Represents a logical state that a single Finite State Machine may exist in.
///
/// This is generally useful when attempting to implement ringlets that
/// behave differently depending on whether the Finite State Machine is
/// suspending, resuming, or restarting.
public enum FSMStatus: Hashable, Codable, Sendable, CaseIterable {

    /// Represents the normal operation of the Finite State Machine.
    ///
    /// The Finite State Machine is not suspended and is not in an accepting
    /// state.
    case executing(transitioned: Bool)

    /// Represents a Finite State Machine that is in an accepting state and
    /// has executed that accepting state at least once.
    case finished

    /// Represents a Finite State Machine that has transitioned back to the
    /// initial state.
    case restarted(transitioned: Bool)

    /// Represents a Finite State Machine that must restart in the next ringlet.
    case restarting

    /// Represents a Finite State Machine that has just been resumed and is
    /// ready to execute the previously suspended state.
    case resumed(transitioned: Bool)

    /// Represents a Finite State Machine currently in the suspend state, but
    /// that should move to the previously suspended state.
    case resuming

    /// Represents a Finite State Machine that is suspended and should execute
    /// the suspend state.
    case suspended(transitioned: Bool)

    /// Represents a Finite State Machine that is currently not suspended, but
    /// must transition to the suspend state.
    case suspending

    /// An array containing all possible cases, tied to all possible associated
    /// values.
    public static var allCases: [FSMStatus] {
        [
            .executing(transitioned: false),
            .executing(transitioned: true),
            .finished,
            .restarted(transitioned: false),
            .restarted(transitioned: true),
            .restarting,
            .resumed(transitioned: false),
            .resumed(transitioned: true),
            .resuming,
            .suspended(transitioned: false),
            .suspended(transitioned: true),
            .suspending,
        ]
    }

    /// Returns whether `self` contains a transition associated value, otherwise
    /// false.
    public var transitioned: Bool {
        switch self {
        case .restarted(let transitioned),
            .executing(let transitioned),
            .resumed(let transitioned),
            .suspended(let transitioned):
            return transitioned
        default:
            return false
        }
    }

}
