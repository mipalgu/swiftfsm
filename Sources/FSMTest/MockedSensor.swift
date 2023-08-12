import FSM

public struct MockedSensor<Value>: SensorHandler where Value: DataStructure {

    public let id: String

    private let _takeSnapshot: () -> Value

    public init(id: String, takeSnapshot: @escaping () -> Value) {
        self.id = id
        self._takeSnapshot = takeSnapshot
    }

    public func takeSnapshot() -> Value {
        self._takeSnapshot()
    }

}
