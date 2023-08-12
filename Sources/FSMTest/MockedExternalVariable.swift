import FSM

public struct MockedExternalVariable<Value>: ExternalVariableHandler where Value: DataStructure {

    public let id: String

    public let initialValue: Value

    private let _takeSnapshot: () -> Value

    private let _saveSnapshot: (Value) -> Void

    public init(
        id: String,
        initialValue: Value,
        takeSnapshot: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void = { _ in }
    ) {
        self.id = id
        self.initialValue = initialValue
        self._takeSnapshot = takeSnapshot
        self._saveSnapshot = saveSnapshot
    }

    public func takeSnapshot() -> Value {
        self._takeSnapshot()
    }

    public func saveSnapshot(value: Value) {
        self._saveSnapshot(value)
    }

}
