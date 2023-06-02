import FSM

/// A data structure that defines a relationship between two Finite State Machines.
public struct Dependency: DataStructure {

    /// The id of the target Finite State Machine.
    public let fsm: Int

    /// The dependency that relates `fsm` to a second Finite State Machine.
    ///
    /// This dependency specifies both the type of dependency (see
    /// `FSMDependency` for all available categories).
    ///
    /// - SeeAlso: `FSMDependency`.
    public let dependency: FSMDependency

    /// Create a new Dependency.
    ///
    /// - Parameter fsm: The id of the target fsm that this dependency applies to.
    ///
    /// - Parameter dependency: The type of dependency that is modelled by this relationship.
    public init(to fsm: Int, satisfying dependency: FSMDependency) {
        self.fsm = fsm
        self.dependency = dependency
    }

}
