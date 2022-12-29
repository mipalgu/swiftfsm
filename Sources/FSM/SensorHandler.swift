public protocol SensorHandler: EnvironmentHandler where Value: Sensor {

    var value: Value { get }

    mutating func takeSnapshot()

}
