import FSM

struct InMemorySensor<Value: SensorValue>: SensorHandler {

    private let resolvedID: Int

    let id: String

    private(set) var value: Value

    init(id: String, initialValue: Value) {
        self.id = id
        self.value = initialValue
        self.resolvedID = StateRegistrar.id(of: id)
    }

    mutating func takeSnapshot() {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return
        }
        self.value = value
    }

}
