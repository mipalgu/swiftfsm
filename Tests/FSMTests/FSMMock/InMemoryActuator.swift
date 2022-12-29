import FSM

struct InMemoryActuator<Value: Actuator>: ActuatorHandler {

    private let resolvedID: Int

    let id: String

    var value: Value

    init(id: String) {
        self.id = id
        self.value = Value()
        self.resolvedID = StateRegistrar.id(of: id)
    }

    mutating func saveSnapshot() {
        inMemoryData[resolvedID] = value
    }

}
