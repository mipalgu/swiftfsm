public protocol EnvironmentVariables {

    associatedtype Data: DataStructure, EmptyInitialisable

}

public extension EnvironmentVariables {

    typealias Sensor<Handler: SensorHandler> = SensorProperty<Data, Handler>

}
