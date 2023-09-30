import FSM

public final class SensorHandlerMock<Value: SensorValue>: SensorHandler {

    public enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case takeSnapshot

    }

    private let _nonNilValue: () -> Value
    private let _id: String
    private let _takeSnapshot: () -> Value

    public private(set) var calls: [Call] = []

    public var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    public var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    public var nonNilValue: Value {
        self._nonNilValue()
    }

    public var id: String {
        calls.append(.id)
        return _id
    }

    public convenience init<T>(id: String, value: Value, nonNilValue: T? = nil) where T == Value {
        let nonNilValue = nonNilValue ?? value
        let value = value
        self.init(
            id: id,
            nonNilValue: { nonNilValue },
            takeSnapshot: { value }
        )
    }

    public convenience init<T>(id: String, value: Value, nonNilValue: T) where T? == Value {
        let nonNilValue = nonNilValue
        let value = value
        self.init(
            id: id,
            nonNilValue: { nonNilValue },
            takeSnapshot: { value }
        )
    }

    public init(id: String, nonNilValue: @escaping () -> Value, takeSnapshot: @escaping () -> Value) {
        self._id = id
        self._nonNilValue = nonNilValue
        self._takeSnapshot = takeSnapshot
    }

    public func takeSnapshot() -> Value {
        calls.append(.takeSnapshot)
        return _takeSnapshot()
    }

}
