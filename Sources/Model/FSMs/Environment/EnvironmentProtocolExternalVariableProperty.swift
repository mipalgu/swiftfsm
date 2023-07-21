import FSM

@propertyWrapper
public struct EnvironmentProtocolExternalVariableProperty
    <Value: ExternalVariableValue>: ExternalVariableValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: EnvironmentProtocolExternalVariableProperty<Value> {
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
