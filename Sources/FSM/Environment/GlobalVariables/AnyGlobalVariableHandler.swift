public struct AnyGlobalVariableHandler {

    private let _base: () -> any GlobalVariableHandler
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: (UnsafeMutableRawPointer, Sendable) -> Void

    public var base: any GlobalVariableHandler {
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
        self.init(
            base: { base },
            id: { base.id },
            saveSnapshot: { base.value = $0 as! Base.Value },
            takeSnapshot: { base.value as Sendable },
            updateEnvironment: updateEnvironment
        )
    }

    public init(
        base: @escaping () -> any GlobalVariableHandler,
        id: @escaping () -> String,
        saveSnapshot: @escaping (Sendable) -> Void,
        takeSnapshot: @escaping () -> Sendable,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self._base = base
        self._id = id
        self._saveSnapshot = saveSnapshot
        self._takeSnapshot = takeSnapshot
        self._updateEnvironment = updateEnvironment
    }

    public func update(environment: UnsafeMutableRawPointer, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
