@propertyWrapper
public struct SensorProperty<Root: EnvironmentSnapshot, Handler: SensorHandler>: AnySensorProperty {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public let projectedValue: Handler

    public var wrappedValue: Handler.Value {
        projectedValue.value
    }

    public var erasedMapPath: AnyKeyPath {
        mapPath as AnyKeyPath
    }

    public var typeErased: Any {
        return AnySensorHandler(projectedValue, mapsTo: mapPath) as Any
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.projectedValue = handler
    }

}
