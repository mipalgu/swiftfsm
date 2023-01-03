public struct AnyExternalVariableHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _value: () -> Sendable
    private let _setValue: (Sendable) -> Void
    private let _saveSnapshot: () -> Void
    private let _takeSnapshot: () -> Void
    private let _updateFromEnvironment: (Environment) -> Void
    private let _updateEnvironment: (inout Environment) -> Void

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public var value: Sendable {
        get {
            _value()
        } set {
            _setValue(newValue)
        }
    }

    public init<Base: ExternalVariableHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        var base = base
        self._base = { base }
        self._id = { base.id }
        self._value = { base.value as Sendable }
        self._setValue = { base.value = unsafeBitCast($0, to: Base.Value.self) }
        self._saveSnapshot = { base.saveSnapshot() }
        self._takeSnapshot = { base.takeSnapshot() }
        self._updateFromEnvironment = {
            guard let value = $0[keyPath: keyPath] else {
                return
            }
            base.value = value
        }
        self._updateEnvironment = { $0[keyPath: keyPath] = base.value }
    }

    public mutating func saveSnapshot() {
        _saveSnapshot()
    }

    public mutating func takeSnapshot() {
        _takeSnapshot()
    }

    public mutating func update(from environment: Environment) {
        _updateFromEnvironment(environment)
    }

    public func update(environment: inout Environment) {
        _updateEnvironment(&environment)
    }

}
