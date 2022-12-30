@propertyWrapper
public struct GlobalVariableProperty<Root, Value: GlobalVariableValue> {

    public let mapPath: WritableKeyPath<Root, Value?>

    public private(set) var projectedValue: InMemoryGlobalVariable<Value>

    public var wrappedValue: Value {
        get {
            projectedValue.value
        } set {
            projectedValue.value = newValue
        }
    }

    public init(id: String, initialValue: Value, mapsTo keyPath: WritableKeyPath<Root, Value?>) {
        self.mapPath = keyPath
        self.projectedValue = InMemoryGlobalVariable(id: id, initialValue: initialValue)
    }

}
