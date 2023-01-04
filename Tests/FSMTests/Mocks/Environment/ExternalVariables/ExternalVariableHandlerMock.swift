import FSM

final class ExternalVariableHandlerMock<Value: ExternalVariableValue>: ExternalVariableHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case saveSnapshot(value: Value)

        case takeSnapshot

    }

    private let _id: String
    private let _saveSnapshot: (Value) -> Void
    private let _takeSnapshot: () -> Value

    private(set) var calls: [Call] = []

    var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
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

    convenience init(id: String, value: Value) {
        var value = value
        self.init(
            id: id,
            saveSnapshot: { value = $0 },
            takeSnapshot: { value }
        )
    }

    init(
        id: String,
        saveSnapshot: @escaping (Value) -> Void,
        takeSnapshot: @escaping () -> Value
    ) {
        self._id = id
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
