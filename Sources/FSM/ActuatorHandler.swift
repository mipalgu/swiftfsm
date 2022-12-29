public protocol ActuatorHandler: EnvironmentHandler where Value: Actuator {

    var value: Value { get set }

    mutating func saveSnapshot()

}
