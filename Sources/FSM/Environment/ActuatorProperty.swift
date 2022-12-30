@propertyWrapper
public struct ActuatorProperty<Root, Handler: ActuatorHandler> {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public private(set) var projectedValue: Handler

    public var wrappedValue: Handler.Value {
        get {
            projectedValue.value
        } set {
            projectedValue.value = newValue
        }
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.projectedValue = handler
    }

}
