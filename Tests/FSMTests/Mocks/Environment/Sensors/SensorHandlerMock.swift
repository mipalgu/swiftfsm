import FSM

final class SensorHandlerMock<Value: SensorValue>: SensorHandler {

    enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case getValue

        case takeSnapshot

    }

    private let _id: String
    private let getValue: () -> Value
    private let _takeSnapshot: () -> Void

    private(set) var calls: [Call] = []

    var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    var getValueCalls: Int {
        self.calls.lazy.filter { $0 == .getValue }.count
    }

    var takeSnapshotCalls: Int {
        self.calls.lazy.filter { $0 == .takeSnapshot }.count
    }

    var id: String {
        calls.append(.id)
        return _id
    }

    var value: Value {
        calls.append(.getValue)
        return getValue()
    }

    convenience init(
        id: String,
        takeSnapshot: @escaping () -> Void = {}
    ) where Value: EmptyInitialisable {
        self.init(
            id: id,
            value: Value(),
            takeSnapshot: takeSnapshot
        )
    }

    convenience init(
        id: String,
        value: Value,
        takeSnapshot: @escaping () -> Void = {}
    ) {
        let value = value
        self.init(
            id: id,
            getValue: { value },
            takeSnapshot: takeSnapshot
        )
    }

    init(
        id: String,
        getValue: @escaping () -> Value,
        takeSnapshot: @escaping () -> Void = {}
    ) {
        self._id = id
        self.getValue = getValue
        self._takeSnapshot = takeSnapshot
    }

    func takeSnapshot() {
        calls.append(.takeSnapshot)
        _takeSnapshot()
    }

}
