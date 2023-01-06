public enum FSMStatus: Hashable, Codable, Sendable, CaseIterable {

    case executing(transitioned: Bool)

    case finished

    case restarted(transitioned: Bool)

    case restarting

    case resumed(transitioned: Bool)

    case resuming

    case suspended(transitioned: Bool)

    case suspending

    public static var allCases: [FSMStatus] {
        [
            .executing(transitioned: false),
            .executing(transitioned: true),
            .finished,
            .restarted(transitioned: false),
            .restarted(transitioned: true),
            .restarting,
            .resumed(transitioned: false),
            .resumed(transitioned: true),
            .resuming,
            .suspended(transitioned: false),
            .suspended(transitioned: true),
            .suspending
        ]
    }

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
