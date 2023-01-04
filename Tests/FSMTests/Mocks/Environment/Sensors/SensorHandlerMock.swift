import FSM

final class SensorHandlerMock<Value: SensorValue>: SensorHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case takeSnapshot

    }

    private let _id: String
    private let _takeSnapshot: () -> Value

    private(set) var calls: [Call] = []

    var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    var id: String {
        calls.append(.id)
        return _id
    }

    convenience init(id: String, value: Value) {
        let value = value
        self.init(
            id: id,
            takeSnapshot: { value }
        )
    }

    init(id: String, takeSnapshot: @escaping () -> Value) {
        self._id = id
        self._takeSnapshot = takeSnapshot
    }

    func takeSnapshot() -> Value {
        calls.append(.takeSnapshot)
        return _takeSnapshot()
    }

}
