import FSM

@propertyWrapper
public struct FSMEnvironmentGlobalVariableProperty<Value: GlobalVariableValue>: GlobalVariableValue {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: FSMEnvironmentGlobalVariableProperty<Value> {
        self
    }

    public init(wrappedValue: Value? = nil) {
        self.wrappedValue = wrappedValue
    }

}
