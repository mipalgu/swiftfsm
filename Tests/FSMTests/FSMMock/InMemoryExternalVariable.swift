import FSM

struct InMemoryExternalVariable<Value: ExternalVariableValue>: ExternalVariableHandler {

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

    mutating func takeSnapshot() {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return
        }
        self.value = value
    }

}
