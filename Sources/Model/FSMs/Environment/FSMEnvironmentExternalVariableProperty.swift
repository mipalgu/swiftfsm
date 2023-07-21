import FSM

@propertyWrapper
public struct FSMEnvironmentExternalVariableProperty<Value: ExternalVariableValue>: ExternalVariableValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: FSMEnvironmentExternalVariableProperty<Value> {
        self
    }

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

}
