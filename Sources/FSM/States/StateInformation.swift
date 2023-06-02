public struct StateInformation: Hashable, Codable, Sendable {

    public var id: Int

    public var name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

}
