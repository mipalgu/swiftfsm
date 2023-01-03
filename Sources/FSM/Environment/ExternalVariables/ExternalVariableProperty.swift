@propertyWrapper
public struct ExternalVariableProperty<
    Root: EnvironmentSnapshot,
    Handler: ExternalVariableHandler
>: AnyExternalVariableProperty {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public private(set) var projectedValue: Handler

    public var wrappedValue: Handler.Value {
        get {
            projectedValue.value
        } set {
            projectedValue.value = newValue
        }
    }

    public var erasedMapPath: AnyKeyPath {
        mapPath as AnyKeyPath
    }

    public var typeErased: Any {
        AnyExternalVariableHandler(projectedValue, mapsTo: mapPath)
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.projectedValue = handler
    }

}
