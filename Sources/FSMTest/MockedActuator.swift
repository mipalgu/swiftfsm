import FSM

public struct MockedActuator<Value>: ActuatorHandler where Value: DataStructure {

    public let id: String

    public let initialValue: Value

    private let _saveSnapshot: (Value) -> Void

    public init(id: String, initialValue: Value, saveSnapshot: @escaping (Value) -> Void = { _ in }) {
        self.id = id
        self.initialValue = initialValue
        self._saveSnapshot = saveSnapshot
    }

    public func saveSnapshot(value: Value) {
        self._saveSnapshot(value)
    }

}
