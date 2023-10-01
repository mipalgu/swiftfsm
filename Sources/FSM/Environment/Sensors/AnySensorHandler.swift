public struct AnySensorHandler<Environment: EnvironmentSnapshot> {

    private let _base: () -> Any
    private let _id: () -> String
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: (UnsafeMutablePointer<Environment>, Sendable) -> Void

    public var base: Any {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: SensorHandler>(
        _ base: Base,
        updateEnvironment: @Sendable @escaping (UnsafeMutablePointer<Environment>, Sendable) -> Void
    ) {
        self._base = { base }
        self._id = { base.id }
        self._takeSnapshot = { base.takeSnapshot() as Sendable }
        self._updateEnvironment = updateEnvironment
    }

    public func takeSnapshot() -> Sendable {
        _takeSnapshot()
    }

    public func update(environment: UnsafeMutablePointer<Environment>, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
