public struct StateInformation: Hashable, Codable, Sendable {

    public var id: Int

    public var name: String

    public init(name: String) {
        let id = StateRegistrar.id(of: name)
        self.init(id: id, name: name)
    }

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

}
