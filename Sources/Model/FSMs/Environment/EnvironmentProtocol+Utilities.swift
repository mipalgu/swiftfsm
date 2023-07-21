import FSM

extension EnvironmentProtocol {

    public typealias Actuator<Value: ActuatorValue> = EnvironmentProtocolActuatorProperty<Value>

    public typealias ExternalVariable<Value: ExternalVariableValue>
        = EnvironmentProtocolExternalVariableProperty<Value>

    public typealias GlobalVariable<Value: GlobalVariableValue>
        = EnvironmentProtocolGlobalVariableProperty<Value>

    public typealias Sensor<Value: SensorValue> = EnvironmentProtocolSensorProperty<Value>

}
