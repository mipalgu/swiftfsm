import FSM

struct InMemoryExternalVariable<Value: ExternalVariable>: ExternalVariableHandler {

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

    mutating func takeSnapshot() {
        guard let value = inMemoryData[resolvedID] as? Value else {
            return
        }
        self.value = value
    }

}
