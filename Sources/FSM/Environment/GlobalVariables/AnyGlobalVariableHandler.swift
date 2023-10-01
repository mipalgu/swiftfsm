public struct AnyGlobalVariableHandler {

    private let _base: () -> Any
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: (UnsafeMutableRawPointer, Sendable) -> Void

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
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        var base = base
        self._base = { base }
        self._id = { base.id }
        self._saveSnapshot = { base.value = $0 as! Base.Value }
        self._takeSnapshot = { base.value as Sendable }
        self._updateEnvironment = updateEnvironment
    }

    public func update(environment: UnsafeMutableRawPointer, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
