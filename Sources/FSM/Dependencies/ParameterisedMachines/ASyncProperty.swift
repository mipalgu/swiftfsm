@propertyWrapper
public struct ASyncProperty<Result: DataStructure>: DataStructure {

    public let wrappedValue: ParameterisedMachine<Result>

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
        self.wrappedValue = parameterisedMachine
    }

}
