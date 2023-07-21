import FSM

@propertyWrapper
public struct EnvironmentProtocolGlobalVariableProperty<Value: GlobalVariableValue>:
    GlobalVariableValue, AnyEnvironmentProtocolVariable {

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

    public func valuePath<Environment: EnvironmentProtocol>(
        _ keyPath: PartialKeyPath<Environment>
    ) -> PartialKeyPath<Environment> {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolGlobalVariableProperty<Value>>.self
        )
        let valuePath: WritableKeyPath<Environment, Value?> = actualKeyPath.appending(path: \.wrappedValue)
        return valuePath
    }

}
