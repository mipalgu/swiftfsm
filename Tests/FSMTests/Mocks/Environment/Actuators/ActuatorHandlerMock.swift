import FSM

final class ActuatorHandlerMock<Value: ActuatorValue>: ActuatorHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case getValue

        case setValue(newValue: Value)

        case saveSnapshot

    }

    private let _id: String
    private let getValue: () -> Value
    private let setValue: (Value) -> Void
    private let _saveSnapshot: () -> Void

    private(set) var calls: [Call] = []

    var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    var getValueCalls: Int {
        self.calls.lazy.filter { $0 == .getValue }.count
    }

    var setValueCalls: [Value] {
        self.calls.compactMap {
            if case .setValue(let newValue) = $0 {
                return newValue
            } else {
                return nil
            }
        }
    }

    var saveSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .saveSnapshot }.count
    }

    var id: String {
        calls.append(.id)
        return _id
    }

    var value: Value {
        get {
            calls.append(.getValue)
            return getValue()
        } set {
            calls.append(.setValue(newValue: newValue))
            setValue(newValue)
        }
    }

    convenience init(
        id: String,
        saveSnapshot: @escaping () -> Void = {}
    ) where Value: EmptyInitialisable {
        self.init(
            id: id,
            value: Value(),
            saveSnapshot: saveSnapshot
        )
    }

    convenience init(
        id: String,
        value: Value,
        saveSnapshot: @escaping () -> Void = {}
    ) {
        var value = value
        self.init(
            id: id,
            getValue: { value },
            setValue: { value = $0 },
            saveSnapshot: saveSnapshot
        )
    }

    init(
        id: String,
        getValue: @escaping () -> Value,
        setValue: @escaping (Value) -> Void,
        saveSnapshot: @escaping () -> Void = {}
    ) {
        self._id = id
        self.getValue = getValue
        self.setValue = setValue
        self._saveSnapshot = saveSnapshot
    }

    func saveSnapshot() {
        calls.append(.saveSnapshot)
        _saveSnapshot()
    }

}
