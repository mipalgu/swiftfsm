import FSM

final class ActuatorHandlerMock<Value: ActuatorValue>: ActuatorHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case initialValue

        case saveSnapshot(value: Value)

    }

    private let _id: String
    private let _initialValue: () -> Value
    private let _saveSnapshot: (Value) -> Void

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

    var id: String {
        calls.append(.id)
        return _id
    }

    var initialValue: Value {
        calls.append(.initialValue)
        return _initialValue()
    }

    init(
        id: String,
        initialValue: Value,
        saveSnapshot: @escaping (Value) -> Void = { _ in }
    ) {
        self._id = id
        self._initialValue = { initialValue }
        self._saveSnapshot = saveSnapshot
    }

    func saveSnapshot(value: Value) {
        calls.append(.saveSnapshot(value: value))
        _saveSnapshot(value)
    }

}
