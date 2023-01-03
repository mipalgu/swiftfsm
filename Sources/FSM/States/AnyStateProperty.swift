public protocol AnyStateProperty {

    var information: StateInformation { get }

    var erasedEnvironmentVariables: Any { get }

    var erasedState: Sendable { get }

    var context: Sendable { get }

    func erasedTransitions(for root: Any) -> Sendable

}
