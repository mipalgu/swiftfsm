public protocol SensorHandler: EnvironmentHandler, CombinationsConvertible where Value: SensorValue {

    func takeSnapshot() -> Value

}
