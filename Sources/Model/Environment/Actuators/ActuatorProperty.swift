import FSM

@propertyWrapper
public struct ActuatorProperty<Root: EnvironmentSnapshot, Handler: ActuatorHandler>: AnyActuatorProperty {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public var projectedValue: Self {
        self
    }

    public var wrappedValue: Handler

    public var erasedInitialValue: Sendable {
        wrappedValue.initialValue as Sendable
    }

    public var erasedMapPath: AnyKeyPath {
        mapPath as AnyKeyPath
    }

    public var typeErased: Any {
        AnyActuatorHandler(wrappedValue, mapsTo: mapPath)
    }

    public init(
        handler: Handler,
        mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>
    ) {
        self.mapPath = keyPath
        self.wrappedValue = handler
    }

}
