import FSM

public final class SensorHandlerMock<Value: SensorValue>: SensorHandler {

    public enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case takeSnapshot

    }

    private let _id: String
    private let _takeSnapshot: () -> Value

    public private(set) var calls: [Call] = []

    public var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    public var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    public var id: String {
        calls.append(.id)
        return _id
    }

    public convenience init(id: String, value: Value) {
        let value = value
        self.init(
            id: id,
            takeSnapshot: { value }
        )
    }

    public init(id: String, takeSnapshot: @escaping () -> Value) {
        self._id = id
        self._takeSnapshot = takeSnapshot
    }

    public func takeSnapshot() -> Value {
        calls.append(.takeSnapshot)
        return _takeSnapshot()
    }

}
