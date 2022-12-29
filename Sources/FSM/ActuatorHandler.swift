public protocol ActuatorHandler: EnvironmentHandler where Value: ActuatorValue {

    var value: Value { get set }

    mutating func saveSnapshot()

}
