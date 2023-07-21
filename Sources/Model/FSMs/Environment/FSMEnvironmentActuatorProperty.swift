import FSM

@propertyWrapper
public struct FSMEnvironmentActuatorProperty<Value: ActuatorValue>: ActuatorValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: FSMEnvironmentActuatorProperty<Value> {
        self
    }

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

}
