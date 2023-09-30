import FSM

public struct MockedSensor<Value>: SensorHandler where Value: DataStructure {

    public let nonNilValue: Value

    public let id: String

    private let _takeSnapshot: () -> Value

    public init<T>(id: String, nonNilValue: T, takeSnapshot: @escaping () -> Value) where T? == Value {
        self.nonNilValue = nonNilValue
        self.id = id
        self._takeSnapshot = takeSnapshot
    }

    public init(id: String, takeSnapshot: @escaping () -> Value) {
        self.nonNilValue = takeSnapshot()
        self.id = id
        self._takeSnapshot = takeSnapshot
    }

    public func takeSnapshot() -> Value {
        self._takeSnapshot()
    }

}
