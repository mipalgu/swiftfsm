public protocol EnvironmentVariables {

    associatedtype Snapshot: EnvironmentSnapshot

}

public extension EnvironmentVariables {

    typealias Actuator<Handler: ActuatorHandler> = ActuatorProperty<Snapshot, Handler>

    typealias ExternalVariable<Handler: ExternalVariableHandler> = ExternalVariableProperty<Snapshot, Handler>

    typealias Sensor<Handler: SensorHandler> = SensorProperty<Snapshot, Handler>

}
