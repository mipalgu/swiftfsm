public protocol SensorHandler: EnvironmentHandler where Value: SensorValue {

    var value: Value { get }

    mutating func takeSnapshot()

}
