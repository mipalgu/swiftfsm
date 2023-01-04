@propertyWrapper
public struct ExternalVariableProperty<
    Root: EnvironmentSnapshot,
    Handler: ExternalVariableHandler
>: AnyExternalVariableProperty {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public var projectedValue: Self {
        self
    }

    public var wrappedValue: Handler

    public var erasedMapPath: AnyKeyPath {
        mapPath as AnyKeyPath
    }

    public var typeErased: Any {
        AnyExternalVariableHandler(wrappedValue, mapsTo: mapPath)
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.wrappedValue = handler
    }

}
