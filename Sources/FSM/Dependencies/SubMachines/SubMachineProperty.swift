//@propertyWrapper
//public struct SubMachineProperty: DataStructure, DependencyCalculatable {
//
//    public var dependency: FSMDependency {
//        .submachine(id: projectedValue.id)
//    }
//
//    public var projectedValue: SubMachine {
//        wrappedValue.submachine
//    }
//
//    public var wrappedValue: Controller
//
//    public init(name: String) {
//        self.init(subMachine: SubMachine(name: name))
//    }
//
//    init(subMachine: SubMachine) {
//        self.wrappedValue = Controller(submachine: subMachine)
//    }
//
//}
