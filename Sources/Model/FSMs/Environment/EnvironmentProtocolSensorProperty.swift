import FSM

@propertyWrapper
public struct EnvironmentProtocolSensorProperty<Value: SensorValue>:
    SensorValue, AnyEnvironmentProtocolVariable {

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var wrappedValue: Value!

    public var projectedValue: EnvironmentProtocolSensorProperty<Value> {
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
            to: WritableKeyPath<Environment, EnvironmentProtocolSensorProperty<Value>>.self
        )
        let valuePath: WritableKeyPath<Environment, Value?> = actualKeyPath.appending(path: \.wrappedValue)
        return valuePath
    }

}
