import FSM

public struct InMemorySensor<Value: SensorValue>: SensorHandler {

    private let resolvedID: Int

    public let id: String

    private let initialValue: Value

    public init(id: String, initialValue: Value) {
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public func takeSnapshot() -> Value {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return initialValue
        }
        return value
    }

}
