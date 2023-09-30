import FSM

public final class ExternalVariableHandlerMock<Value: ExternalVariableValue>: ExternalVariableHandler {

    public enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case initialValue

        case saveSnapshot(value: Value)

        case takeSnapshot

    }

    private let _nonNilValue: () -> Value
    private let _id: String
    private let _initialValue: () -> Value
    private let _saveSnapshot: (Value) -> Void
    private let _takeSnapshot: () -> Value

    public private(set) var calls: [Call] = []

    public var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    public var initialValueCalls: Int {
        self.calls.lazy.filter { $0 == .initialValue }.count
    }

    public var saveSnapshotCalls: [Value] {
        self.calls.compactMap {
            if case .saveSnapshot(let newValue) = $0 {
                return newValue
            } else {
                return nil
            }
        }
    }

    public var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    public var nonNilValue: Value {
        _nonNilValue()
    }

    public var id: String {
        calls.append(.id)
        return _id
    }

    public var initialValue: Value {
        calls.append(.initialValue)
        return _initialValue()
    }

    public convenience init<T>(id: String, value: Value, nonNilValue: T, initialValue: Value? = nil)
    where T? == Value {
        let initialValue = initialValue ?? value
        var value = value
        self.init(
            id: id,
            nonNilValue: { nonNilValue },
            initialValue: { initialValue },
            saveSnapshot: { value = $0 },
            takeSnapshot: { value }
        )
    }

    public convenience init<T>(id: String, value: Value, nonNilValue: T? = nil, initialValue: Value? = nil)
    where T == Value {
        let nonNilValue = nonNilValue ?? value
        let initialValue = initialValue ?? value
        var value = value
        self.init(
            id: id,
            nonNilValue: { nonNilValue },
            initialValue: { initialValue },
            saveSnapshot: { value = $0 },
            takeSnapshot: { value }
        )
    }

    public init<T>(
        id: String,
        nonNilValue: @escaping () -> T,
        initialValue: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void,
        takeSnapshot: @escaping () -> Value
    ) where T == Value {
        self._id = id
        self._nonNilValue = nonNilValue
        self._initialValue = initialValue
        self._saveSnapshot = saveSnapshot
        self._takeSnapshot = takeSnapshot
    }

    public init<T>(
        id: String,
        nonNilValue: @escaping () -> T,
        initialValue: @escaping () -> Value,
        saveSnapshot: @escaping (Value) -> Void,
        takeSnapshot: @escaping () -> Value
    ) where T? == Value {
        self._id = id
        self._nonNilValue = nonNilValue
        self._initialValue = initialValue
        self._saveSnapshot = saveSnapshot
        self._takeSnapshot = takeSnapshot
    }

    public func saveSnapshot(value: Value) {
        calls.append(.saveSnapshot(value: value))
        _saveSnapshot(value)
    }

    public func takeSnapshot() -> Value {
        calls.append(.takeSnapshot)
        return _takeSnapshot()
    }

}
