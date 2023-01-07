import FSM

final class ExternalVariableHandlerMock<Value: ExternalVariableValue>: ExternalVariableHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case initialValue

        case saveSnapshot(value: Value)

        case takeSnapshot

    }

    private let _id: String
    private let _initialValue: () -> Value
    private let _saveSnapshot: (Value) -> Void
    private let _takeSnapshot: () -> Value

    private(set) var calls: [Call] = []

    var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    var initialValueCalls: Int {
        self.calls.lazy.filter { $0 == .initialValue }.count
    }

    var saveSnapshotCalls: [Value] {
        self.calls.compactMap {
            if case .saveSnapshot(let newValue) = $0 {
                return newValue
            } else {
                return nil
            }
        }
    }

    var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    var id: String {
        calls.append(.id)
        return _id
    }

    var initialValue: Value {
        calls.append(.initialValue)
        return _initialValue()
    }

    convenience init(id: String, value: Value, initialValue: Value? = nil) {
        let initialValue = initialValue ?? value
        var value = value
        self.init(
            id: id,
            initialValue: { initialValue },
            saveSnapshot: { value = $0 },
            takeSnapshot: { value }
        )
    }

    init(
        id: String,
        initialValue: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void,
        takeSnapshot: @escaping () -> Value
    ) {
        self._id = id
        self._initialValue = initialValue
        self._saveSnapshot = saveSnapshot
        self._takeSnapshot = takeSnapshot
    }

    func saveSnapshot(value: Value) {
        calls.append(.saveSnapshot(value: value))
        _saveSnapshot(value)
    }

    func takeSnapshot() -> Value {
        calls.append(.takeSnapshot)
        return _takeSnapshot()
    }

}
