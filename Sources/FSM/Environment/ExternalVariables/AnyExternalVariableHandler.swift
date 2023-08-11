public struct AnyExternalVariableHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _saveSnapshot: (Sendable) -> Void
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: @Sendable (UnsafeMutablePointer<Environment>, Sendable) -> Void

    public var index: Int = -1

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: ExternalVariableHandler>(
        _ base: Base,
        updateEnvironment: @Sendable @escaping (UnsafeMutablePointer<Environment>, Sendable) -> Void
    ) {
        self._base = { base }
        self._id = { base.id }
        self._saveSnapshot = { base.saveSnapshot(value: $0 as! Base.Value) }
        self._takeSnapshot = { base.takeSnapshot() as Sendable }
        self._updateEnvironment = updateEnvironment
    }

    public func saveSnapshot(value: Sendable) {
        _saveSnapshot(value)
    }

    public func takeSnapshot() -> Sendable {
        _takeSnapshot()
    }

    public func update(environment: UnsafeMutablePointer<Environment>, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
