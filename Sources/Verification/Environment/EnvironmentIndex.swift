enum EnvironmentIndex: Hashable, Codable, Sendable {

    case actuator(Int)

    case externalVariable(Int)

    case globalVariable(Int)

    case sensor(Int)

    var index: Int {
        switch self {
        case
            .actuator(let index),
            .externalVariable(let index),
            .globalVariable(let index),
            .sensor(let index):
            return index
        }
    }

}
