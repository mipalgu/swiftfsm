public struct InMemoryActuator<Value: ActuatorValue>: ActuatorHandler {

    private let resolvedID: Int

    public let id: String

    public init(id: String) {
        self.id = id
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public func saveSnapshot(value: Value) {
        inMemoryData[resolvedID] = value
    }

}
