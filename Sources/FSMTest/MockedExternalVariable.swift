import FSM

public struct MockedExternalVariable<Value>: ExternalVariableHandler where Value: DataStructure {

    public let nonNilValue: Value

    public let id: String

    public let initialValue: Value

    private let _takeSnapshot: () -> Value

    private let _saveSnapshot: (Value) -> Void

    public init<T>(
        id: String,
        nonNilValue: T,
        initialValue: T? = nil,
        takeSnapshot: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void = { _ in }
    ) where T? == Value {
        self.nonNilValue = nonNilValue
        self.id = id
        self.initialValue = initialValue
        self._takeSnapshot = takeSnapshot
        self._saveSnapshot = saveSnapshot
    }

    public init(
        id: String,
        initialValue: Value,
        takeSnapshot: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void = { _ in }
    ) {
        self.nonNilValue = takeSnapshot()
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
