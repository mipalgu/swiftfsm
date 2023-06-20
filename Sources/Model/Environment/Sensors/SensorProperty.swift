import FSM

@propertyWrapper
public struct SensorProperty<Root: EnvironmentSnapshot, Handler: SensorHandler>: AnySensorProperty {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public var projectedValue: Self {
        self
    }

    public var wrappedValue: Handler

    public var erasedMapPath: AnyKeyPath {
        mapPath as AnyKeyPath
    }

    public var typeErased: Any {
        return AnySensorHandler(wrappedValue, mapsTo: mapPath) as Any
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.wrappedValue = handler
    }

}
