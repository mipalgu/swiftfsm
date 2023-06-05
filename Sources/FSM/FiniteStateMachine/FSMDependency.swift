/// A dependency that relates a Finite State Machine to another Finite State
/// Machine.
public enum FSMDependency: DataStructure {

    /// The target Finite State Machine may be called asynchronously by the
    /// source Finite State Machine.
    ///
    /// - Parameter id: The id of the target Finite State Machine.
    case async(id: Int)

    /// The target Finite State Machine must be called synchronously by the
    /// source Finite State Machine.
    ///
    /// - Parameter id: The id of the target Finite State Machine.
    case sync(id: Int)

    /// The target Finite State Machine must be called asynchronously by the
    /// a source Finite State Machine, and the target may return results as it
    /// is executing.
    case partial(id: Int)

    /// The target Finite State Machine must be controlled by the source
    /// Finite State Machine in an owner/slave relationship.
    case submachine(id: Int)

}
