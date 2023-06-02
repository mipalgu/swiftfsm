/// A type-erased actuator handler.
public struct AnyActuatorHandler<Environment: EnvironmentSnapshot> {

    /// Fetch the base that was used to create this type-erased actuator
    /// handler.
    private let _base: () -> Any

    /// Fetch the id of the actuator handler.
    private let _id: () -> String

    /// Fetch the initial value of the actuator handler.
    private let _initialValue: () -> Sendable

    /// Save a value to the environment.
    private let _saveSnapshot: (Sendable) -> Void

    /// Update an environment snapshot with a value.
    private let _updateEnvironment: (inout Environment, Sendable) -> Void

    /// The index of the actuator handler when it is stored within an array.
    public var index: Int = -1

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
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self._base = { base }
        self._id = { base.id }
        self._initialValue = { base.initialValue as Sendable }
        self._saveSnapshot = { base.saveSnapshot(value: unsafeBitCast($0, to: Base.Value.self)) }
        self._updateEnvironment = { $0[keyPath: keyPath] = unsafeBitCast($1, to: Base.Value.self) }
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
    public func update(environment: inout Environment, with value: Sendable) {
        _updateEnvironment(&environment, value)
    }

}
