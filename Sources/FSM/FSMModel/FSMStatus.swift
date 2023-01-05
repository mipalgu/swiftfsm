public enum FSMStatus: Hashable, Codable, Sendable {

    case executing(transitioned: Bool)

    case finished

    case restarted(transitioned: Bool)

    case restarting

    case resumed(transitioned: Bool)

    case resuming

    case suspended(transitioned: Bool)

    case suspending

    public var transitioned: Bool {
        switch self {
        case .restarted(let transitioned),
            .executing(let transitioned),
            .resumed(let transitioned),
            .suspended(let transitioned):
            return transitioned
        default:
            return false
        }
    }

}
