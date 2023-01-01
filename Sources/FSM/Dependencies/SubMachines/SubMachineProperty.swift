@propertyWrapper
public struct SubMachineProperty: DataStructure {

    public let wrappedValue: SubMachine

    public init(name: String) {
        self.init(subMachine: SubMachine(name: name))
    }

    init(subMachine: SubMachine) {
        self.wrappedValue = subMachine
    }

}
