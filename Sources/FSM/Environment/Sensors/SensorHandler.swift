public protocol SensorHandler: EnvironmentHandler where Value: SensorValue {

    func takeSnapshot() -> Value

}
