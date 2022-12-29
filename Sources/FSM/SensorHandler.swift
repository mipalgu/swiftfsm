public protocol SensorHandler: EnvironmentHandler {

    var value: Value { get }

    mutating func takeSnapshot()

}
