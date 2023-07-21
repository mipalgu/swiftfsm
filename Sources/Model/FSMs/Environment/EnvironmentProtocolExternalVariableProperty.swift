import FSM

@propertyWrapper
public struct EnvironmentProtocolExternalVariableProperty<Value: ExternalVariableValue>:
    ExternalVariableValue, AnyEnvironmentProtocolVariable {

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

    public func valuePath<Environment: EnvironmentProtocol>(
        _ keyPath: PartialKeyPath<Environment>
    ) -> PartialKeyPath<Environment> {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolExternalVariableProperty<Value>>.self
        )
        let valuePath: WritableKeyPath<Environment, Value?> = actualKeyPath.appending(path: \.wrappedValue)
        return valuePath
    }

}
