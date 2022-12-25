import FSM

struct EmptyState: StateProtocol {

    typealias Context = EmptyDataStructure
    typealias TypeErasedVersion = Self

    let name: String

    init(name: String) {
        self.name = name
    }

}
