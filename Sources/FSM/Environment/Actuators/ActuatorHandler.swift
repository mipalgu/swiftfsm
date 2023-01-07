public protocol ActuatorHandler: EnvironmentHandler where Value: ActuatorValue {

    var initialValue: Value { get }

    func saveSnapshot(value: Value)

}
