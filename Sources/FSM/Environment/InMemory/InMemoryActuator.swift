public struct InMemoryActuator<Value: ActuatorValue>: ActuatorHandler {

    private let resolvedID: Int

    public let id: String

    public var value: Value

    public init(id: String, initialValue: Value) {
        self.id = id
        self.value = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public mutating func saveSnapshot() {
        inMemoryData[resolvedID] = value
    }

}
