public protocol FiniteStateMachineOperations: Finishable {

    var isSuspended: Bool { get }

    mutating func restart()

    mutating func resume()

    mutating func suspend()

}
