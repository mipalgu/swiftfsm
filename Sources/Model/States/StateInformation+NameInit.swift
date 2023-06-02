import FSM

public extension StateInformation {

    init(name: String) {
        let id = IDRegistrar.id(of: name)
        self.init(id: id, name: name)
    }

}
