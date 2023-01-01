public struct ParameterisedMachine<Result: DataStructure>: DataStructure {

    public enum CallMethod: Hashable, Codable, Sendable, CaseIterable {

        case asynchronous

        case synchronous

    }

    public let id: Int

    public let name: String

    public let parameters: [Int: String]

    public let parameterOrder: [Int]

    public let callMethod: CallMethod

    public init(name: String, parameters: [String], returnType: Result.Type, callMethod: CallMethod) {
        let id = IDRegistrar.id(of: name)
        let ids = parameters.map { (IDRegistrar.id(of: $0), $0) }
        let parameters = Dictionary(uniqueKeysWithValues: ids)
        let parameterOrder = ids.map(\.0)
        self.init(
            id: id,
            name: name,
            parameters: parameters,
            parameterOrder: parameterOrder,
            returnType: returnType,
            callMethod: callMethod
        )
    }

    init(
        id: Int,
        name: String,
        parameters: [Int: String],
        parameterOrder: [Int],
        returnType _: Result.Type,
        callMethod: CallMethod
    ) {
        self.id = id
        self.name = name
        self.parameters = parameters
        self.parameterOrder = parameterOrder
        self.callMethod = callMethod
    }

}
