@propertyWrapper
public struct GlobalVariableProperty<Root, Handler: GlobalVariableHandler> {

    public let mapPath: WritableKeyPath<Root, Handler.Value?>

    public private(set) var projectedValue: Handler

    public var wrappedValue: Handler.Value {
        get {
            projectedValue.value
        } set {
            projectedValue.value = newValue
        }
    }

    public init<Value: GlobalVariableValue>(
        id: String,
        initialValue: Value,
        mapsTo keyPath: WritableKeyPath<Root, Value?>
    ) where Handler == InMemoryGlobalVariable<Value> {
        self.init(handler: InMemoryGlobalVariable(id: id, initialValue: initialValue), mapsTo: keyPath)
    }

    public init(handler: Handler, mapsTo keyPath: WritableKeyPath<Root, Handler.Value?>) {
        self.mapPath = keyPath
        self.projectedValue = handler
    }

}
