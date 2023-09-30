import FSM

private var handlerValues: [String: Any?] = [:]

private var handlerCalls: [String: [GenericCall]] = [:]

private enum GenericCall {

    case id

    case getValue

    case setValue(newValue: Any?)

}

public final class GlobalVariableHandlerMock<Value: GlobalVariableValue>: GlobalVariableHandler {

    public enum Call: Equatable, Hashable, Codable, Sendable {

        case id

        case getValue

        case setValue(newValue: Value)

        fileprivate var genericCall: GenericCall {
            switch self {
            case .id:
                return .id
            case .getValue:
                return .getValue
            case .setValue(let newValue):
                return .setValue(newValue: newValue as Any?)
            }
        }

        fileprivate init(from call: GenericCall) {
            switch call {
            case .id:
                self = .id
            case .getValue:
                self = .getValue
            case .setValue(newValue: let genericNewValue):
                self = .setValue(newValue: genericNewValue as! Value)
            }
        }

    }

    public let nonNilValue: Value

    private let _id: String

    public private(set) var calls: [Call] {
        get {
            handlerCalls[_id]?.map { Call(from: $0) } ?? []
        }
        set {
            handlerCalls[_id] = newValue.map(\.genericCall)
        }
    }

    public var idCalls: Int {
        self.calls.lazy.filter { $0 == .id }.count
    }

    public var getValueCalls: Int {
        self.calls.lazy.filter { $0 == .getValue }.count
    }

    public var setValueCalls: [Value] {
        self.calls.compactMap {
            if case .setValue(let newValue) = $0 {
                return newValue
            } else {
                return nil
            }
        }
    }

    private var _value: Value {
        get {
            guard let value = handlerValues[_id] as? Value else {
                fatalError("Failed to fetch value from handlerValues.")
            }
            return value
        }
        set {
            handlerValues[_id] = newValue as Any?
        }
    }

    public var id: String {
        calls.append(.id)
        return _id
    }

    public var value: Value {
        get {
            calls.append(.getValue)
            return _value
        }
        set {
            calls.append(.setValue(newValue: newValue))
            _value = newValue
        }
    }

    public init<T>(id: String, value: Value, nonNilValue: T? = nil) where T == Value {
        self._id = id
        self.nonNilValue = nonNilValue ?? value
        handlerValues[id] = value
        handlerCalls[id] = []
    }

    public init<T>(id: String, value: Value, nonNilValue: T) where T? == Value {
        self._id = id
        self.nonNilValue = nonNilValue
        handlerValues[id] = value
        handlerCalls[id] = []
    }

}

public extension GlobalVariableHandlerMock {

    static func == (lhs: GlobalVariableHandlerMock<Value>, rhs: GlobalVariableHandlerMock<Value>) -> Bool {
        lhs._id == rhs._id && lhs._value == rhs._value
    }

}

public extension GlobalVariableHandlerMock {

    func hash(into hasher: inout Hasher) {
        hasher.combine(_id)
        hasher.combine(_value)
    }

}

public extension GlobalVariableHandlerMock {

    enum CodingKeys: CodingKey {

        case id

        case value

    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let value = try container.decode(Value.self, forKey: .value)
        self.init(id: id, value: value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(_value, forKey: .value)
    }

}
