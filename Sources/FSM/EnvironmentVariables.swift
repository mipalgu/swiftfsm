public protocol EnvironmentVariables: DataStructure {}

public extension EnvironmentVariables {

    typealias Sensor<Handler> = SensorProperty<Handler> where Handler: SensorHandler

}
