import FSM

@propertyWrapper
public struct EnvironmentProtocolActuatorProperty<Value: ActuatorValue>: ActuatorValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: EnvironmentProtocolActuatorProperty<Value> {
        get {
            self
        } set {
            self = newValue
        }
    }

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

}
