public struct FSMInformation: DataStructure {

    public let id: Int

    public let name: String

    public init<FSM: FSMModel>(fsm: FSM) {
        let id = IDRegistrar.id(of: fsm.name)
        self.init(id: id, name: fsm.name)
    }

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

}
