/// A type-erased actuator handler.
public struct AnyActuatorHandler {

    /// Fetch the base that was used to create this type-erased actuator
    /// handler.
    private let _base: () -> any ActuatorHandler

    /// Fetch the id of the actuator handler.
    private let _id: () -> String

    /// Fetch the initial value of the actuator handler.
    private let _initialValue: () -> Sendable

    /// Save a value to the environment.
    private let _saveSnapshot: (Sendable) -> Void

    /// Update an environment snapshot with a value.
    private let _updateEnvironment: @Sendable (UnsafeMutableRawPointer, Sendable) -> Void

    /// The base that was used to create this type-erased actuator handler.
    public var base: Any {
        _base()
    }

    /// The id of the actuator handler.
    public var id: String {
        _id()
    }

    /// The initial value of the actuator handler.
    public var initialValue: Sendable {
        _initialValue()
    }

    /// Create a type-erased actuator handler.
    ///
    /// - Parameter base: The base actuator handler.
    ///
    /// - Parameter keyPath: The key path that associates this actuator with
    /// a value within an environment snapshot.
    public init<Base: ActuatorHandler>(
        _ base: Base,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self._base = { base }
        self._id = { base.id }
        self._initialValue = { base.initialValue as Sendable }
        self._saveSnapshot = { base.saveSnapshot(value: $0 as! Base.Value) }
        self._updateEnvironment = updateEnvironment
    }

    /// Save a value to the environment.
    ///
    /// - Parameter value: The value to save.
    public func saveSnapshot(value: Sendable) {
        _saveSnapshot(value)
    }

    /// Update an environment snapshot with a value.
    ///
    /// - Parameter environment: The environment snapshot to update.
    ///
    /// - Parameter value: The value to update the environment snapshot with.
    public func update(environment: UnsafeMutableRawPointer, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
