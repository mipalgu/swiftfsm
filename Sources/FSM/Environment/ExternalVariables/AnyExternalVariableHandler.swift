public struct AnyExternalVariableHandler {

    private let _base: () -> any ExternalVariableHandler
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: @Sendable (UnsafeMutableRawPointer, Sendable) -> Void

    public var base: any ExternalVariableHandler {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: ExternalVariableHandler>(
        _ base: Base,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self.init(
            base: { base },
            id: { base.id },
            saveSnapshot: { base.saveSnapshot(value: $0 as! Base.Value) },
            takeSnapshot: { base.takeSnapshot() as Sendable },
            updateEnvironment: updateEnvironment
        )
    }

    public init(
        base: @Sendable @escaping () -> any ExternalVariableHandler,
        id: @Sendable @escaping () -> String,
        saveSnapshot: @Sendable @escaping (Sendable) -> Void,
        takeSnapshot: @Sendable @escaping () -> Sendable,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self._base = base
        self._id = id
        self._saveSnapshot = saveSnapshot
        self._takeSnapshot = takeSnapshot
        self._updateEnvironment = updateEnvironment
    }

    public func saveSnapshot(value: Sendable) {
        _saveSnapshot(value)
    }

    public func takeSnapshot() -> Sendable {
        _takeSnapshot()
    }

    public func update(environment: UnsafeMutableRawPointer, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
