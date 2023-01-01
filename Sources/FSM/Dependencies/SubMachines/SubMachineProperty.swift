@propertyWrapper
public struct SubMachineProperty: DataStructure {

    public var projectedValue: SubMachine {
        wrappedValue.submachine
    }

    public var wrappedValue: Controller

    public init(name: String) {
        self.init(subMachine: SubMachine(name: name))
    }

    init(subMachine: SubMachine) {
        self.wrappedValue = Controller(submachine: subMachine)
    }

}
