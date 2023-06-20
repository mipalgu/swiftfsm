import FSM

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
        }
        set {
            inMemoryGlobalVariableData[resolvedID] = newValue
        }
    }

    public init(id: String, initialValue: Value) {
        self.id = id
        self.initialValue = initialValue
        self.resolvedID = IDRegistrar.id(of: id)
    }

}

extension InMemoryGlobalVariable {

    public enum CodingKeys: CodingKey {
        case id
        case initialValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let initialValue = try container.decode(Value.self, forKey: .initialValue)
        self.init(id: id, initialValue: initialValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(initialValue, forKey: .initialValue)
    }

}
