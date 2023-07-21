import FSM

@propertyWrapper
public struct EnvironmentProtocolGlobalVariableProperty<Value: GlobalVariableValue>: GlobalVariableValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: EnvironmentProtocolGlobalVariableProperty<Value> {
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
