public struct AnySensorHandler {

    private let _base: () -> any SensorHandler
    private let _id: () -> String
    private let _takeSnapshot: () -> Sendable
    private let _updateEnvironment: (UnsafeMutableRawPointer, Sendable) -> Void

    public var base: any SensorHandler {
        _base()
    }

    public var id: String {
        _id()
    }

    public init<Base: SensorHandler>(
        _ base: Base,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self.init(
            base: { base },
            id: { base.id },
            takeSnapshot: { base.takeSnapshot() as Sendable },
            updateEnvironment: updateEnvironment
        )
    }

    public init(
        base: @Sendable @escaping () -> any SensorHandler,
        id: @Sendable @escaping () -> String,
        takeSnapshot: @Sendable @escaping () -> Sendable,
        updateEnvironment: @Sendable @escaping (UnsafeMutableRawPointer, Sendable) -> Void
    ) {
        self._base = base
        self._id = id
        self._takeSnapshot = takeSnapshot
        self._updateEnvironment = updateEnvironment
    }

    public func takeSnapshot() -> Sendable {
        _takeSnapshot()
    }

    public func update(environment: UnsafeMutableRawPointer, with value: Sendable) {
        _updateEnvironment(environment, value)
    }

}
