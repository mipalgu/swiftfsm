public struct AnyActuatorHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _updateEnvironment: (inout Environment, Sendable) -> Void

    public var index: Int = -1

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: ActuatorHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self._base = { base }
        self._id = { base.id }
        self._saveSnapshot = { base.saveSnapshot(value: unsafeBitCast($0, to: Base.Value.self)) }
        self._updateEnvironment = { $0[keyPath: keyPath] = unsafeBitCast($1, to: Base.Value.self) }
    }

    public func saveSnapshot(value: Sendable) {
        _saveSnapshot(value)
    }

    public func update(environment: inout Environment, with value: Sendable) {
        _updateEnvironment(&environment, value)
    }

}
