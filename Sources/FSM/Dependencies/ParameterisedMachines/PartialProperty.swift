@propertyWrapper
public struct PartialProperty<
    Result: DataStructure,
    Partial: DataStructure
>: DataStructure, DependencyCalculatable {

    public var dependency: FSMDependency {
        .partial(id: projectedValue.id)
    }

    public var projectedValue: ParameterisedMachine<Result> {
        wrappedValue.parameterisedMachine
    }

    public var wrappedValue: PartialCaller<Result, Partial>

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
        self.wrappedValue = PartialCaller(parameterisedMachine: parameterisedMachine)
    }

}
