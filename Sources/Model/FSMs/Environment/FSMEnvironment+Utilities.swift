import FSM

extension FSMEnvironment {

    public typealias Actuator<Value: ActuatorValue> = FSMEnvironmentActuatorProperty<Value>

    public typealias ExternalVariable<Value: ExternalVariableValue>
        = FSMEnvironmentExternalVariableProperty<Value>

    public typealias GlobalVariable<Value: GlobalVariableValue> = FSMEnvironmentGlobalVariableProperty<Value>

    public typealias Sensor<Value: SensorValue> = FSMEnvironmentSensorProperty<Value>

}
