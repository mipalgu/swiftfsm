public struct AnyGlobalVariableHandler<Environment: EnvironmentSnapshot> {

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

    public var value: Sendable {
        get {
            _takeSnapshot()
        } nonmutating set {
            _saveSnapshot(newValue)
        }
    }

    public init<Base: GlobalVariableHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        var base = base
        self._base = { base }
        self._id = { base.id }
        self._saveSnapshot = { base.value = $0 as! Base.Value }
        self._takeSnapshot = { base.value as Sendable }
        self._updateEnvironment = { $0[keyPath: keyPath] = $1 as! Base.Value }
    }

    public func update(environment: inout Environment, with value: Sendable) {
        _updateEnvironment(&environment, value)
    }

}
