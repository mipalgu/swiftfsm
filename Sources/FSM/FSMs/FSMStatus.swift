public enum FSMStatus: Hashable, Codable, Sendable, CaseIterable {

    case executing

    case finished

    case restarting

    case resuming

    case suspended

    case suspending

}
