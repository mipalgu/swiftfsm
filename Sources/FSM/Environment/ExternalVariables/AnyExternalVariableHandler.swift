public struct AnyExternalVariableHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: (inout Environment, Sendable) -> Void

    public var index: Int = -1

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: ExternalVariableHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self._base = { base }
        self._id = { base.id }
        self._saveSnapshot = { base.saveSnapshot(value: $0 as! Base.Value) }
        self._takeSnapshot = { base.takeSnapshot() as Sendable }
        self._updateEnvironment = { $0[keyPath: keyPath] = $1 as! Base.Value }
    }

    public func saveSnapshot(value: Sendable) {
        _saveSnapshot(value)
    }

    public func takeSnapshot() -> Sendable {
        _takeSnapshot()
    }

    public func update(environment: inout Environment, with value: Sendable) {
        _updateEnvironment(&environment, value)
    }

}
