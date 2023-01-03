public struct AnySensorHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _value: () -> Any
    private let _takeSnapshot: () -> Void
    private let _updateEnvironment: (inout Environment) -> Void

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public var value: Any {
        _value()
    }

    public init<Base: SensorHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        var base = base
        self._base = { base }
        self._id = { base.id }
        self._value = { base.value as Any }
        self._takeSnapshot = { base.takeSnapshot() }
        self._updateEnvironment = { $0[keyPath: keyPath] = base.value }
    }

    public mutating func takeSnapshot() {
        _takeSnapshot()
    }

    public func update(environment: inout Environment) {
        _updateEnvironment(&environment)
    }

}
