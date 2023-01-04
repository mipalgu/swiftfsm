public protocol ActuatorHandler: EnvironmentHandler where Value: ActuatorValue {

    func saveSnapshot(value: Value)

}
