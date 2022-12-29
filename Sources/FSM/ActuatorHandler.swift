public protocol ActuatorHandler: EnvironmentHandler {

    var value: Value { get set }

    mutating func saveSnapshot()

}
