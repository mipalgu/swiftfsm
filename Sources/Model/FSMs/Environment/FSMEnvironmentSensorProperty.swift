import FSM

@propertyWrapper
public struct FSMEnvironmentSensorProperty<Value: SensorValue>: SensorValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: FSMEnvironmentSensorProperty<Value> {
        self
    }

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

}
