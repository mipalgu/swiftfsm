@propertyWrapper
public struct ASyncProperty<Result: DataStructure>: DataStructure {

    public let projectedValue: Caller<Result>

    public var wrappedValue: ParameterisedMachine<Result> {
        projectedValue.parameterisedMachine
    }

    public init(name: String, parameters: [String] = []) where Result == EmptyDataStructure {
        self.init(name: name, parameters: parameters, returnType: EmptyDataStructure.self)
    }

    public init(name: String, parameters: [String] = [], returnType: Result.Type) {
        let parameterisedMachine = ParameterisedMachine(
            name: name,
            parameters: parameters,
            returnType: returnType,
            callMethod: .asynchronous
        )
        self.projectedValue = Caller(parameterisedMachine: parameterisedMachine)
    }

}
