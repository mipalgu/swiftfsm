public struct FSMInformation: DataStructure {

    public let id: Int

    public let name: String

    public let dependencies: [FSMDependency]

    public init<FSM: FSMModel>(fsm: FSM) {
        let id = IDRegistrar.id(of: fsm.name)
        self.init(id: id, name: fsm.name, dependencies: fsm.dependencies)
    }

    init(id: Int, name: String, dependencies: [FSMDependency]) {
        self.id = id
        self.name = name
        self.dependencies = dependencies
    }

}
