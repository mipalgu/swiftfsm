@propertyWrapper
public struct SensorProperty<Root, Handler: SensorHandler> {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public let projectedValue: Handler

    public var wrappedValue: Handler.Value {
        projectedValue.value
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.projectedValue = handler
    }

}
