import FSM

public struct InMemoryExternalVariable<Value: ExternalVariableValue>: ExternalVariableHandler {

    public let nonNilValue: Value

    private let resolvedID: Int

    public let id: String

    public let initialValue: Value

    public init(id: String) where Value: EmptyInitialisable {
        self.init(id: id, initialValue: Value())
    }

    public init<T>(id: String, initialValue: T) where T == Value {
        self.nonNilValue = initialValue
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public init<T>(id: String, initialValue: T?, nonNilValue: T) where T? == Value {
        self.nonNilValue = initialValue
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

    public func saveSnapshot(value: Value) {
        inMemoryData[resolvedID] = value
    }

    public func takeSnapshot() -> Value {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return initialValue
        }
        return value
    }

}
