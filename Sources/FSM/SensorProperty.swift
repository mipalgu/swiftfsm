@propertyWrapper
public struct SensorProperty<Handler: SensorHandler> {

    public let projectedValue: Handler

    public var wrappedValue: Handler.Value {
        projectedValue.value
    }

    public init(handler: Handler) {
        self.projectedValue = handler
    }

}
