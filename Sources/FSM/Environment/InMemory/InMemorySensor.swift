public struct InMemorySensor<Value: SensorValue>: SensorHandler {

    private let resolvedID: Int

    public let id: String

    public private(set) var value: Value

    public init(id: String, initialValue: Value) {
        self.id = id
        self.value = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public mutating func takeSnapshot() {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return
        }
        self.value = value
    }

}
