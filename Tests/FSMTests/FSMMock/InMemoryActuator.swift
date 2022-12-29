import FSM

struct InMemoryActuator<Value: ActuatorValue>: ActuatorHandler {

    private let resolvedID: Int

    let id: String

    var value: Value

    init(id: String, initialValue: Value) {
        self.id = id
        self.value = initialValue
        self.resolvedID = StateRegistrar.id(of: id)
    }

    mutating func saveSnapshot() {
        inMemoryData[resolvedID] = value
    }

}
