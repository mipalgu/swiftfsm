//@propertyWrapper
//public struct SyncProperty<Result: DataStructure>: DataStructure, DependencyCalculatable {
//
//    public var dependency: FSMDependency {
//        .sync(id: projectedValue.id)
//    }
//
//    public var projectedValue: ParameterisedMachine<Result> {
//        wrappedValue.parameterisedMachine
//    }
//
//    public var wrappedValue: Caller<Result>
//
//    public init(name: String, parameters: [String] = []) where Result == EmptyDataStructure {
//        self.init(name: name, parameters: parameters, returnType: EmptyDataStructure.self)
//    }
//
//    public init(name: String, parameters: [String] = [], returnType: Result.Type) {
//        let parameterisedMachine = ParameterisedMachine(
//            name: name,
//            parameters: parameters,
//            returnType: returnType,
//            callMethod: .synchronous
//        )
//        self.wrappedValue = Caller(parameterisedMachine: parameterisedMachine)
//    }
//
//}
