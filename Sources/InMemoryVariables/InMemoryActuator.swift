import FSM

public struct InMemoryActuator<Value: ActuatorValue>: ActuatorHandler {

    private let resolvedID: Int

    public let id: String

    public let initialValue: Value

    public init(id: String) where Value: EmptyInitialisable {
        self.init(id: id, initialValue: Value())
    }

    public init(id: String, initialValue: Value) {
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public func saveSnapshot(value: Value) {
        inMemoryData[resolvedID] = value
    }

}
