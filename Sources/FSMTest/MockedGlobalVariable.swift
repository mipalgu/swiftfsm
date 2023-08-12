import FSM

public struct MockedGlobalVariable<Value>: GlobalVariableHandler where Value: DataStructure {

    public let id: String

    public let initialValue: Value

    private let _takeSnapshot: () -> Value

    private let _saveSnapshot: (Value) -> Void

    public var value: Value {
        get {
            _takeSnapshot()
        } set {
            _saveSnapshot(newValue)
        }
    }

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

}
