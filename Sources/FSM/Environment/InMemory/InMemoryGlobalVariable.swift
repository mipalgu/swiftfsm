private var inMemoryGlobalVariableData: [Int: Sendable] = [:]

public struct InMemoryGlobalVariable<Value: GlobalVariableValue>: GlobalVariableHandler {

    private let resolvedID: Int

    public let id: String

    private let initialValue: Value

    public var value: Value {
        get {
            guard let value = inMemoryGlobalVariableData[resolvedID] as? Value else {
                return initialValue
            }
            return value
        } set {
            inMemoryGlobalVariableData[resolvedID] = newValue
        }
    }

    public init(id: String, initialValue: Value) {
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = StateRegistrar.id(of: id)
    }

}
